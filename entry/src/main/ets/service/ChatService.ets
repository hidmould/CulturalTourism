/**
 * 大模型对话服务 - 流式对话、多模型切换、上下文记忆
 */
import { HttpClient } from '../network/HttpClient'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'
import { http } from '@kit.NetworkKit'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { ChatMessage, Conversation } from '../model/Models'
import { relationalStore } from '@kit.ArkData'
import {
  ModelType,
  ModelConfig,
  MODEL_CONFIGS,
  MessageRole,
  TABLE_CONVERSATION,
  TABLE_MESSAGE
} from '../common/Constants'

export class ChatService {
  private static instance: ChatService
  private currentModelType: ModelType = ModelType.GENERAL
  private activeHttpRequest: http.HttpRequest | null = null

  static getInstance(): ChatService {
    if (!ChatService.instance) {
      ChatService.instance = new ChatService()
    }
    return ChatService.instance
  }

  getCurrentModel(): ModelType {
    return this.currentModelType
  }

  setCurrentModel(type: ModelType): void {
    this.currentModelType = type
  }

  getModelConfig(type: ModelType): ModelConfig {
    let config = MODEL_CONFIGS.find(c => c.type === type)
    return config ?? MODEL_CONFIGS[0]
  }

  /**
   * 创建新对话
   */
  async createConversation(title: string, modelType: string): Promise<number> {
    let store = await DatabaseHelper.getInstance().getStore()
    let valueBucket: relationalStore.ValuesBucket = {
      'title': title,
      'model_type': modelType,
      'last_message_time': Date.now(),
      'create_time': Date.now()
    }
    let rowId = await store.insert(TABLE_CONVERSATION, valueBucket)
    return rowId
  }

  /**
   * 更新对话标题和摘要
   */
  async updateConversation(convId: number, title: string, summary: string): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let valueBucket: relationalStore.ValuesBucket = {}
    if (title !== undefined) {
      valueBucket['title'] = title
    }
    if (summary !== undefined) {
      valueBucket['summary'] = summary
    }
    valueBucket['last_message_time'] = Date.now()
    let predicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
    predicates.equalTo('id', convId)
    await store.update(valueBucket, predicates)
  }

  /**
   * 根据消息内容生成对话标题（取第一条用户消息前12字）
   */
  async generateTitleFromMessages(convId: number): Promise<string> {
    let msgs = await this.getMessages(convId)
    for (let i = 0; i < msgs.length; i++) {
      let msg = msgs[i]
      if (msg.role === MessageRole.USER) {
        let content = msg.content.trim()
        if (content.length > 0) {
          return content.length > 12 ? content.substring(0, 12) + '...' : content
        }
      }
    }
    return ''
  }

  /**
   * 获取单个对话信息
   */
  async getConversationById(convId: number): Promise<Conversation | null> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
    predicates.equalTo('id', convId)
    let resultSet = await store.query(predicates)
    if (!resultSet.goToFirstRow()) {
      resultSet.close()
      return null
    }
    let conv = new Conversation()
    conv.id = resultSet.getLong(resultSet.getColumnIndex('id'))
    conv.title = resultSet.getString(resultSet.getColumnIndex('title'))
    conv.summary = resultSet.getString(resultSet.getColumnIndex('summary'))
    conv.modelType = resultSet.getString(resultSet.getColumnIndex('model_type'))
    conv.lastMessageTime = resultSet.getLong(resultSet.getColumnIndex('last_message_time'))
    conv.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
    conv.messageCount = resultSet.getLong(resultSet.getColumnIndex('message_count'))
    resultSet.close()
    return conv
  }

  /**
   * 清空对话消息计数（标记已读）
   */
  async clearMessageCount(convId: number): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let valueBucket: relationalStore.ValuesBucket = {
      'message_count': 0
    }
    let predicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
    predicates.equalTo('id', convId)
    await store.update(valueBucket, predicates)
  }

  /**
   * 获取所有对话列表
   */
  async getConversations(): Promise<Conversation[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
    predicates.orderByDesc('last_message_time')
    let resultSet = await store.query(predicates)

    let list: Conversation[] = []
    while (resultSet.goToNextRow()) {
      let conv = new Conversation()
      conv.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      conv.title = resultSet.getString(resultSet.getColumnIndex('title'))
      conv.summary = resultSet.getString(resultSet.getColumnIndex('summary'))
      conv.modelType = resultSet.getString(resultSet.getColumnIndex('model_type'))
      conv.lastMessageTime = resultSet.getLong(resultSet.getColumnIndex('last_message_time'))
      conv.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
      conv.messageCount = resultSet.getLong(resultSet.getColumnIndex('message_count'))

      // 标题为空或为默认"新对话"时，自动根据首条用户消息生成
      if ((!conv.title || conv.title === '新对话') && conv.id > 0) {
        try {
          let generatedTitle = await this.generateTitleFromMessages(conv.id)
          if (generatedTitle) {
            let titleBucket: relationalStore.ValuesBucket = { 'title': generatedTitle }
            let titlePredicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
            titlePredicates.equalTo('id', conv.id)
            await store.update(titleBucket, titlePredicates)
            conv.title = generatedTitle
          }
        } catch (err) {
          // 生成失败不影响列表展示
        }
      }

      list.push(conv)
    }
    resultSet.close()
    return list
  }

  /**
   * 删除对话
   */
  async deleteConversation(convId: number): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()

    // 删除关联消息
    let msgPredicates = new relationalStore.RdbPredicates(TABLE_MESSAGE)
    msgPredicates.equalTo('conversation_id', convId)
    await store.delete(msgPredicates)

    // 删除对话
    let convPredicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
    convPredicates.equalTo('id', convId)
    await store.delete(convPredicates)
  }

  /**
   * 搜索对话
   */
  async searchConversations(keyword: string): Promise<Conversation[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let sql = `SELECT * FROM ${TABLE_CONVERSATION} WHERE title LIKE ? OR summary LIKE ? ORDER BY last_message_time DESC`
    let args: string[] = [`%${keyword}%`, `%${keyword}%`]
    let resultSet = await store.querySql(sql, args)

    let list: Conversation[] = []
    while (resultSet.goToNextRow()) {
      let conv = new Conversation()
      conv.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      conv.title = resultSet.getString(resultSet.getColumnIndex('title'))
      conv.summary = resultSet.getString(resultSet.getColumnIndex('summary'))
      conv.modelType = resultSet.getString(resultSet.getColumnIndex('model_type'))
      conv.lastMessageTime = resultSet.getLong(resultSet.getColumnIndex('last_message_time'))
      conv.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
      conv.messageCount = resultSet.getLong(resultSet.getColumnIndex('message_count'))

      // 标题为空或为默认"新对话"时，自动根据首条用户消息生成
      if ((!conv.title || conv.title === '新对话') && conv.id > 0) {
        try {
          let generatedTitle = await this.generateTitleFromMessages(conv.id)
          if (generatedTitle) {
            let titleBucket: relationalStore.ValuesBucket = { 'title': generatedTitle }
            let titlePredicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
            titlePredicates.equalTo('id', conv.id)
            await store.update(titleBucket, titlePredicates)
            conv.title = generatedTitle
          }
        } catch (err) {
          // 生成失败不影响列表展示
        }
      }

      list.push(conv)
    }
    resultSet.close()
    return list
  }

  /**
   * 获取对话消息
   */
  async getMessages(convId: number): Promise<ChatMessage[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_MESSAGE)
    predicates.equalTo('conversation_id', convId)
    predicates.orderByAsc('create_time')
    let resultSet = await store.query(predicates)

    let list: ChatMessage[] = []
    while (resultSet.goToNextRow()) {
      let msg = new ChatMessage()
      msg.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      msg.conversationId = resultSet.getLong(resultSet.getColumnIndex('conversation_id'))
      msg.role = resultSet.getString(resultSet.getColumnIndex('role'))
      msg.content = resultSet.getString(resultSet.getColumnIndex('content'))
      msg.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
      list.push(msg)
    }
    resultSet.close()
    return list
  }

  /**
   * 保存消息到数据库
   */
  async saveMessage(convId: number, role: string, content: string): Promise<number> {
    let store = await DatabaseHelper.getInstance().getStore()
    let valueBucket: relationalStore.ValuesBucket = {
      'conversation_id': convId,
      'role': role,
      'content': content,
      'create_time': Date.now()
    }
    let rowId: number

    try {
      rowId = await store.insert(TABLE_MESSAGE, valueBucket)
    } catch (err) {
      // 表可能损坏或列不匹配，重建表后重试
      try {
        await store.executeSql(`DROP TABLE IF EXISTS ${TABLE_MESSAGE}`)
      } catch (e) {
        // 忽略
      }
      await store.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_MESSAGE} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT DEFAULT '',
        create_time INTEGER DEFAULT 0
      )`)
      rowId = await store.insert(TABLE_MESSAGE, valueBucket)
    }

    // 更新对话消息计数（失败不影响消息保存）
    try {
      let convPredicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
      convPredicates.equalTo('id', convId)
      let resultSet = await store.query(convPredicates)
      let currentCount: number = 0
      if (resultSet.goToFirstRow()) {
        let colIndex = resultSet.getColumnIndex('message_count')
        if (colIndex >= 0) {
          currentCount = resultSet.getLong(colIndex)
        }
      }
      resultSet.close()

      let updateBucket: relationalStore.ValuesBucket = {
        'last_message_time': Date.now(),
        'message_count': currentCount + 1
      }
      convPredicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
      convPredicates.equalTo('id', convId)
      await store.update(updateBucket, convPredicates)
    } catch (err) {
      // 更新计数失败不影响消息保存
    }

    return rowId
  }

  /**
   * 构建消息上下文（最近N轮对话）
   */
  async buildContext(convId: number, maxMessages: number = 20): Promise<Record<string, string>[]> {
    let messages = await this.getMessages(convId)
    let context: Record<string, string>[] = []

    // 取最近的消息
    let startIndex = messages.length > maxMessages ? messages.length - maxMessages : 0
    for (let i = startIndex; i < messages.length; i++) {
      let msg = messages[i]
      let item: Record<string, string> = {
        'role': msg.role,
        'content': msg.content
      }
      context.push(item)
    }

    return context
  }

  /**
   * 取消正在进行的流式请求
   */
  cancelStream(): void {
    if (this.activeHttpRequest) {
      try {
        this.activeHttpRequest.destroy()
      } catch (e) {
        // 忽略销毁错误
      }
      this.activeHttpRequest = null
    }
  }

  /**
   * 是否有正在进行的流式请求
   */
  isStreaming(): boolean {
    return this.activeHttpRequest !== null
  }

  /**
   * 更新消息内容（用于将部分内容替换为完整内容）
   */
  async updateMessage(msgId: number, content: string): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let valueBucket: relationalStore.ValuesBucket = {
      'content': content
    }
    let predicates = new relationalStore.RdbPredicates(TABLE_MESSAGE)
    predicates.equalTo('id', msgId)
    await store.update(valueBucket, predicates)
  }

  /**
   * 流式发送消息到大模型
   * @param convId 对话ID
   * @param messages 上下文消息数组
   * @param onChunk 增量数据回调
   * @param onDone 完成回调
   * @param onError 错误回调
   */
  async sendStreamMessage(
    convId: number,
    messages: Record<string, string>[],
    onChunk: (delta: string) => void,
    onDone: (fullContent: string) => void,
    onError: (error: string) => void
  ): Promise<void> {
    let config = this.getModelConfig(this.currentModelType)

    let body = JSON.stringify({
      model: config.modelName,
      messages: messages,
      stream: true
    })

    let headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.apiKey}`,
      'Accept': 'text/event-stream'
    }

    let streamReq = HttpClient.getInstance().createStreamRequest(headers)
    let httpRequest = streamReq.request
    this.activeHttpRequest = httpRequest
    let options = streamReq.options
    options.extraData = body
    let fullContent = ''
    let hasError = false
    let hasReceivedData = false
    let hasDone = false

    // 15秒首包超时兜底：若一直未收到任何数据则自动失败
    let firstByteTimeoutId = setTimeout(() => {
      if (!hasReceivedData && !hasError) {
        hasError = true
        httpRequest.destroy()
        this.activeHttpRequest = null
        onError('请求超时，请检查网络连接或API配置')
      }
    }, 15000)

    // 60秒总超时兜底：防止流永不结束
    let totalTimeoutId = setTimeout(() => {
      if (!hasDone && !hasError) {
        hasError = true
        httpRequest.destroy()
        this.activeHttpRequest = null
        if (fullContent.length > 0) {
          onDone(fullContent)
        } else {
          onError('请求超时，未收到完整回复')
        }
      }
    }, 60000)

    // 记录响应头（调试用）
    httpRequest.on('headersReceive', (header: Object) => {
      console.info('[ChatService] headersReceive: ' + JSON.stringify(header))
    })

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      hasReceivedData = true
      let decoder = new util.TextDecoder()
      let uint8Data = new Uint8Array(data)
      let text = decoder.decode(uint8Data)
      let lines = text.split('\n')

      for (let i = 0; i < lines.length; i++) {
        let line = lines[i].trim()
        if (line.startsWith('data: ')) {
          let jsonStr = line.substring(6)
          if (jsonStr === '[DONE]') {
            if (!hasDone) {
              hasDone = true
              clearTimeout(firstByteTimeoutId)
              clearTimeout(totalTimeoutId)
              httpRequest.destroy()
              this.activeHttpRequest = null
              onDone(fullContent)
            }
            return
          }
          try {
            let json = JSON.parse(jsonStr) as Record<string, Object>
            let choices = json['choices'] as Object[]
            if (choices && choices.length > 0) {
              let choice = choices[0] as Record<string, Object>
              let delta = choice['delta'] as Record<string, Object>
              if (delta) {
                let content = (delta['content'] as string) ?? ''
                if (content) {
                  fullContent += content
                  onChunk(content)
                }
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    })

    httpRequest.on('dataEnd', () => {
      if (hasError || hasDone) {
        return
      }
      clearTimeout(firstByteTimeoutId)
      clearTimeout(totalTimeoutId)
      httpRequest.destroy()
      this.activeHttpRequest = null
      onDone(fullContent)
    })

    httpRequest.requestInStream(config.apiUrl, options).catch((err: Object) => {
      if (!hasError) {
        hasError = true
        clearTimeout(firstByteTimeoutId)
        clearTimeout(totalTimeoutId)
        httpRequest.destroy()
        this.activeHttpRequest = null
        // 如果有已接收的部分内容，仍然通过 onDone 保存，而不是直接报错
        if (fullContent.length > 0) {
          onDone(fullContent)
        } else {
          let error = err as BusinessError
          onError(`网络请求失败: ${error.message || JSON.stringify(err)}`)
        }
      }
    })
  }
}