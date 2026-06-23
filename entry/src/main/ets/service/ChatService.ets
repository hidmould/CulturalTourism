import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { PreferencesHelper } from '../preferences/PreferencesHelper'
import { HttpClient } from '../network/HttpClient'
import { SseParser, MockStreamService } from '../network/SseClient'
import { ApiConfig, SystemPrompts } from '../network/ApiConfig'
import { ChatModel, MessageModel, ModelConfig, DEFAULT_MODELS } from '../model/ChatModel'

/**
 * 聊天消息项
 */
class ChatMessage {
  role: string = ''
  content: string = ''
}

/**
 * 聊天请求体
 */
class ChatRequestBody {
  model: string = ''
  messages: ChatMessage[] = []
  stream: boolean = true
}

/**
 * 对话服务
 * 处理对话创建、消息收发、流式渲染、多模型切换
 */
export class ChatService {
  private static instance: ChatService
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private prefsHelper: PreferencesHelper = PreferencesHelper.getInstance()
  private httpClient: HttpClient = HttpClient.getInstance()
  private currentModel: ModelConfig = DEFAULT_MODELS[0]

  static getInstance(): ChatService {
    if (!ChatService.instance) {
      ChatService.instance = new ChatService()
    }
    return ChatService.instance
  }

  /**
   * 设置当前使用的模型
   */
  setModel(modelType: string): void {
    const model = DEFAULT_MODELS.find(m => m.type === modelType)
    if (model) {
      this.currentModel = model
      this.prefsHelper.saveModelType(modelType)
    }
  }

  /**
   * 获取当前模型
   */
  getCurrentModel(): ModelConfig {
    return this.currentModel
  }

  /**
   * 获取所有可用模型
   */
  getModels(): ModelConfig[] {
    return DEFAULT_MODELS
  }

  /**
   * 创建新对话
   */
  async createChat(title: string): Promise<number> {
    const modelType = await this.prefsHelper.getModelType()
    const values: relationalStore.ValuesBucket = {
      'title': title,
      'model_type': modelType,
      'last_message_time': Date.now(),
      'create_time': Date.now()
    }
    return await this.dbHelper.insert('chat', values)
  }

  /**
   * 获取对话列表
   */
  async getChatList(): Promise<ChatModel[]> {
    const predicates = new relationalStore.RdbPredicates('chat')
    predicates.equalTo('is_deleted', 0)
    predicates.orderByDesc('last_message_time')
    const resultSet = await this.dbHelper.query(predicates)

    const chats: ChatModel[] = []
    while (resultSet.goToNextRow()) {
      const chat = new ChatModel()
      chat.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      chat.title = resultSet.getString(resultSet.getColumnIndex('title'))
      chat.summary = resultSet.getString(resultSet.getColumnIndex('summary'))
      chat.modelType = resultSet.getString(resultSet.getColumnIndex('model_type'))
      chat.lastMessageTime = resultSet.getLong(resultSet.getColumnIndex('last_message_time'))
      chat.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
      chats.push(chat)
    }
    resultSet.close()
    return chats
  }

  /**
   * 删除对话（软删除）
   */
  async deleteChat(chatId: number): Promise<void> {
    const values: relationalStore.ValuesBucket = { 'is_deleted': 1 }
    const predicates = new relationalStore.RdbPredicates('chat')
    predicates.equalTo('id', chatId)
    await this.dbHelper.update('chat', values, predicates)
  }

  /**
   * 搜索对话
   */
  async searchChats(keyword: string): Promise<ChatModel[]> {
    const allChats = await this.getChatList()
    if (!keyword) {
      return allChats
    }
    return allChats.filter(c =>
      c.title.includes(keyword) || c.summary.includes(keyword)
    )
  }

  /**
   * 获取对话的消息列表
   */
  async getMessages(chatId: number): Promise<MessageModel[]> {
    const predicates = new relationalStore.RdbPredicates('message')
    predicates.equalTo('chat_id', chatId)
    predicates.orderByAsc('create_time')
    const resultSet = await this.dbHelper.query(predicates)

    const messages: MessageModel[] = []
    while (resultSet.goToNextRow()) {
      const msg = new MessageModel()
      msg.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      msg.chatId = resultSet.getLong(resultSet.getColumnIndex('chat_id'))
      msg.role = resultSet.getString(resultSet.getColumnIndex('role'))
      msg.content = resultSet.getString(resultSet.getColumnIndex('content'))
      msg.messageType = resultSet.getString(resultSet.getColumnIndex('message_type'))
      msg.structuredData = resultSet.getString(resultSet.getColumnIndex('structured_data'))
      msg.isFavorite = resultSet.getLong(resultSet.getColumnIndex('is_favorite'))
      msg.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
      messages.push(msg)
    }
    resultSet.close()
    return messages
  }

  /**
   * 保存用户消息
   */
  async saveMessage(msg: MessageModel): Promise<number> {
    const values: relationalStore.ValuesBucket = {
      'chat_id': msg.chatId,
      'role': msg.role,
      'content': msg.content,
      'message_type': msg.messageType,
      'structured_data': msg.structuredData,
      'is_favorite': msg.isFavorite,
      'create_time': msg.createTime
    }
    return await this.dbHelper.insert('message', values)
  }

  /**
   * 更新对话摘要和时间
   */
  async updateChatSummary(chatId: number, summary: string): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'summary': summary,
      'last_message_time': Date.now()
    }
    const predicates = new relationalStore.RdbPredicates('chat')
    predicates.equalTo('id', chatId)
    await this.dbHelper.update('chat', values, predicates)
  }

  /**
   * 发送消息并获取AI回复（流式）
   * @param chatId 对话ID
   * @param userMessage 用户消息内容
   * @param onData 流式数据回调
   * @param onDone 完成回调
   * @param onError 错误回调
   */
  async sendMessageStream(
    chatId: number,
    userMessage: string,
    onData: (text: string) => void,
    onDone: (fullContent: string) => void,
    onError: (error: string) => void
  ): Promise<void> {
    // 1. 保存用户消息
    const userMsg = new MessageModel()
    userMsg.chatId = chatId
    userMsg.role = 'user'
    userMsg.content = userMessage
    userMsg.messageType = 'text'
    userMsg.createTime = Date.now()
    await this.saveMessage(userMsg)

    // 2. 获取历史消息构建上下文
    const historyMessages = await this.getMessages(chatId)
    const historyContext = this.buildContext(historyMessages)

    // 3. 获取用户偏好作为系统提示
    const travelPreference = await this.prefsHelper.getTravelPreference()
    const userCity = await this.prefsHelper.getCity()
    const systemPrompt = this.currentModel.type === 'travel'
      ? SystemPrompts.TRAVEL
      : SystemPrompts.GENERAL

    const enhancedPrompt = `${systemPrompt}\n\n用户偏好：${travelPreference}，常住城市：${userCity || '未知'}`

    // 4. 构建请求body
    const messages: ChatMessage[] = []
    const systemMsg = new ChatMessage()
    systemMsg.role = 'system'
    systemMsg.content = enhancedPrompt
    messages.push(systemMsg)
    for (let i = 0; i < historyContext.length; i++) {
      messages.push(historyContext[i])
    }
    const requestUserMsg = new ChatMessage()
    requestUserMsg.role = 'user'
    requestUserMsg.content = userMessage
    messages.push(requestUserMsg)

    const body = new ChatRequestBody()
    body.model = this.currentModel.name
    body.messages = messages
    body.stream = true

    // 5. 检查是否有API Key
    if (!this.currentModel.apiKey) {
      // 使用Mock数据
      MockStreamService.simulateStream(userMessage, onData, () => {
        const fullResponse = MockStreamService.getMockResponse(userMessage)
        this.saveAssistantMessage(chatId, fullResponse)
        this.updateChatSummary(chatId, userMessage.substring(0, 30))
        onDone(fullResponse)
      })
      return
    }

    // 6. 真实API调用
    try {
      const responseText = await this.httpClient.postStream(
        this.currentModel.apiUrl,
        JSON.stringify(body),
        this.currentModel.apiKey
      )

      let fullContent = ''
      const parser = new SseParser(
        (text: string) => {
          fullContent += text
          onData(text)
        },
        () => {
          this.saveAssistantMessage(chatId, fullContent)
          this.updateChatSummary(chatId, userMessage.substring(0, 30))
          onDone(fullContent)
        },
        (error: string) => {
          onError(error)
        }
      )

      parser.push(responseText)
      parser.finish()
    } catch (err) {
      onError(`请求失败: ${JSON.stringify(err)}`)
    }
  }

  /**
   * 构建上下文消息
   */
  private buildContext(messages: MessageModel[]): ChatMessage[] {
    const context: ChatMessage[] = []
    // 取最近10轮对话
    const recentMessages = messages.slice(-20)
    for (const msg of recentMessages) {
      const chatMsg = new ChatMessage()
      chatMsg.role = msg.role
      chatMsg.content = msg.content
      context.push(chatMsg)
    }
    return context
  }

  /**
   * 保存助手回复消息
   */
  private async saveAssistantMessage(chatId: number, content: string): Promise<void> {
    const msg = new MessageModel()
    msg.chatId = chatId
    msg.role = 'assistant'
    msg.content = content
    msg.messageType = this.detectMessageType(content)
    msg.createTime = Date.now()
    await this.saveMessage(msg)
  }

  /**
   * 检测消息类型
   */
  private detectMessageType(content: string): string {
    if (content.includes('Day') || content.includes('路线') || content.includes('行程')) {
      return 'route'
    }
    if (content.includes('美食') || content.includes('推荐') || content.includes('餐厅')) {
      return 'food'
    }
    if (content.includes('景点') || content.includes('游览') || content.includes('介绍')) {
      return 'spot'
    }
    return 'text'
  }
}