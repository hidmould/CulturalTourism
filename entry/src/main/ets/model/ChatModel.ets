/**
 * 对话数据模型
 */
export class ChatModel {
  id: number = 0
  title: string = ''              // 对话标题
  summary: string = ''            // 对话摘要
  modelType: string = 'general'   // 使用的模型类型：general / travel
  lastMessageTime: number = Date.now()
  createTime: number = Date.now()
  isDeleted: number = 0
}

/**
 * 消息数据模型
 */
export class MessageModel {
  id: number = 0
  chatId: number = 0
  role: string = ''               // 'user' | 'assistant'
  content: string = ''
  messageType: string = 'text'    // 'text' | 'route' | 'food' | 'spot'
  structuredData: string = ''     // 结构化JSON数据（路线/美食/景点）
  isFavorite: number = 0          // 是否收藏
  createTime: number = Date.now()
}

/**
 * 模型配置
 */
export class ModelConfig {
  name: string = ''               // 模型名称
  displayName: string = ''        // 显示名称
  apiUrl: string = ''             // API地址
  apiKey: string = ''             // 认证Key
  type: string = ''               // 'general' | 'travel'
}

/**
 * 默认模型配置
 */
export const DEFAULT_MODELS: ModelConfig[] = [
  {
    name: 'DeepSeek-V3',
    displayName: '通用大模型',
    apiUrl: 'https://api.deepseek.com/v1/chat/completions',
    apiKey: '',                   // 后续填入Key
    type: 'general'
  },
  {
    name: 'DeepSeek-R1',
    displayName: '旅游专用模型',
    apiUrl: 'https://api.deepseek.com/v1/chat/completions',
    apiKey: '',                   // 后续填入Key
    type: 'travel'
  }
]