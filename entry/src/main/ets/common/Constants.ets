/**
 * 应用常量配置
 */

// ==================== API 配置 ====================

// DeepSeek V3 大模型
export const DEEPSEEK_API_KEY = 'giREkmEsO_9FoMuu2v_nI3T3aHcgAu_3fe6EuYVPmTkRt-M24L-dxuYfpbCfccPBrj9G8oBTYOgZjnuILmaKPQ'
export const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions'
export const DEEPSEEK_MODEL = 'deepseek-chat'

// 高德天气 API
export const AMAP_WEATHER_KEY = '2f7da6fcd4c6722c58547d6de02f804c'
export const AMAP_WEATHER_URL = 'https://restapi.amap.com/v3/weather/weatherInfo'

// 旅游垂直模型（可配置多个大模型）
export const TRAVEL_MODEL_API_KEY = 'giREkmEsO_9FoMuu2v_nI3T3aHcgAu_3fe6EuYVPmTkRt-M24L-dxuYfpbCfccPBrj9G8oBTYOgZjnuILmaKPQ'
export const TRAVEL_MODEL_API_URL = 'https://api.deepseek.com/v1/chat/completions'
export const TRAVEL_MODEL_NAME = 'deepseek-chat'

// ==================== 数据库配置 ====================

export const DB_NAME = 'CulturalTourism.db'
export const DB_VERSION = 1

// 表名
export const TABLE_USER = 'user_info'
export const TABLE_CONVERSATION = 'conversation'
export const TABLE_MESSAGE = 'message'
export const TABLE_FAVORITE = 'favorite'
export const TABLE_TRIP = 'trip'
export const TABLE_SCENIC_SPOT = 'scenic_spot'

// ==================== Preferences Key ====================

export const PREF_NAME = 'CulturalTourismPrefs'
export const PREF_KEY_TOKEN = 'user_token'
export const PREF_KEY_PASSWORD = 'user_password'
export const PREF_KEY_PHONE = 'user_phone'
export const PREF_KEY_REMEMBER = 'remember_password'
export const PREF_KEY_AUTO_LOGIN = 'auto_login'
export const PREF_KEY_NICKNAME = 'user_nickname'
export const PREF_KEY_AVATAR = 'user_avatar'
export const PREF_KEY_TRAVEL_PREF = 'travel_preference'
export const PREF_KEY_CITY = 'resident_city'
export const PREF_KEY_CURRENT_MODEL = 'current_model'

// ==================== 模型类型 ====================

export enum ModelType {
  GENERAL = 'general',     // 通用大模型
  TRAVEL = 'travel'        // 旅游垂直模型
}

export interface ModelConfig {
  type: ModelType
  name: string
  apiUrl: string
  apiKey: string
  modelName: string
}

export const MODEL_CONFIGS: ModelConfig[] = [
  {
    type: ModelType.GENERAL,
    name: '通用对话模型',
    apiUrl: DEEPSEEK_API_URL,
    apiKey: DEEPSEEK_API_KEY,
    modelName: DEEPSEEK_MODEL
  },
  {
    type: ModelType.TRAVEL,
    name: '旅游专用模型',
    apiUrl: TRAVEL_MODEL_API_URL,
    apiKey: TRAVEL_MODEL_API_KEY,
    modelName: TRAVEL_MODEL_NAME
  }
]

// ==================== 消息角色 ====================

export enum MessageRole {
  USER = 'user',
  ASSISTANT = 'assistant',
  SYSTEM = 'system'
}

// ==================== 旅行偏好 ====================

export enum TravelPreference {
  FAMILY = '亲子',
  SOLO = '独行',
  FOOD = '美食',
  ALL = '综合'
}

// ==================== 景点分类 ====================

export enum ScenicCategory {
  NATURE = '自然风光',
  HISTORY = '历史人文',
  POPULAR = '网红打卡',
  FOOD = '美食街区'
}