/**
 * 大模型对话服务 - 流式对话、多模型切换、上下文记忆
 */
import { HttpClient } from '../network/HttpClient'
import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'
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
    let valueBucket: relationalStore.ValuesBucket = {
      'title': title,
      'summary': summary,
      'last_message_time': Date.now()
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
    let rowId = await store.insert(TABLE_MESSAGE, valueBucket)

    // 更新对话消息计数 - 先查询当前计数
    let convPredicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
    convPredicates.equalTo('id', convId)
    let resultSet = await store.query(convPredicates)
    let currentCount: number = 0
    if (resultSet.goToFirstRow()) {
      currentCount = resultSet.getLong(resultSet.getColumnIndex('message_count'))
    }
    resultSet.close()

    let updateBucket: relationalStore.ValuesBucket = {
      'last_message_time': Date.now(),
      'message_count': currentCount + 1
    }
    convPredicates = new relationalStore.RdbPredicates(TABLE_CONVERSATION)
    convPredicates.equalTo('id', convId)
    await store.update(updateBucket, convPredicates)

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

    let httpRequest = HttpClient.getInstance().createStreamRequest(config.apiUrl, body, headers)
    let fullContent = ''

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      let decoder = new util.TextDecoder()
      let uint8Data = new Uint8Array(data)
      let text = decoder.decode(uint8Data)
      let lines = text.split('\n')

      for (let i = 0; i < lines.length; i++) {
        let line = lines[i].trim()
        if (line.startsWith('data: ')) {
          let jsonStr = line.substring(6)
          if (jsonStr === '[DONE]') {
            continue
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
      httpRequest.destroy()
      onDone(fullContent)
    })
  }
}