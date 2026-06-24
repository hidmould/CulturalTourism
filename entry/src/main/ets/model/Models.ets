/**
 * 数据模型定义
 */

// ==================== 用户模型 ====================

export class UserInfo {
  id: number = 0
  phone: string = ''
  nickname: string = ''
  avatar: string = ''
  travelPreference: string = ''
  residentCity: string = ''
  createTime: number = Date.now()

  static fromJson(json: Record<string, Object>): UserInfo {
    let user = new UserInfo()
    user.id = json['id'] as number ?? 0
    user.phone = json['phone'] as string ?? ''
    user.nickname = json['nickname'] as string ?? ''
    user.avatar = json['avatar'] as string ?? ''
    user.travelPreference = json['travel_preference'] as string ?? ''
    user.residentCity = json['resident_city'] as string ?? ''
    user.createTime = json['create_time'] as number ?? Date.now()
    return user
  }
}

// ==================== 对话模型 ====================

export class Conversation {
  id: number = 0
  title: string = ''
  summary: string = ''
  modelType: string = ''
  lastMessageTime: number = Date.now()
  createTime: number = Date.now()
  messageCount: number = 0

  static fromJson(json: Record<string, Object>): Conversation {
    let conv = new Conversation()
    conv.id = json['id'] as number ?? 0
    conv.title = json['title'] as string ?? ''
    conv.summary = json['summary'] as string ?? ''
    conv.modelType = json['model_type'] as string ?? ''
    conv.lastMessageTime = json['last_message_time'] as number ?? Date.now()
    conv.createTime = json['create_time'] as number ?? Date.now()
    conv.messageCount = json['message_count'] as number ?? 0
    return conv
  }
}

// ==================== 消息模型 ====================

export class ChatMessage {
  id: number = 0
  conversationId: number = 0
  role: string = ''
  content: string = ''
  createTime: number = Date.now()

  static fromJson(json: Record<string, Object>): ChatMessage {
    let msg = new ChatMessage()
    msg.id = json['id'] as number ?? 0
    msg.conversationId = json['conversation_id'] as number ?? 0
    msg.role = json['role'] as string ?? ''
    msg.content = json['content'] as string ?? ''
    msg.createTime = json['create_time'] as number ?? Date.now()
    return msg
  }
}

// ==================== 收藏模型 ====================

export class Favorite {
  id: number = 0
  messageId: number = 0
  conversationId: number = 0
  content: string = ''
  type: string = ''  // spot_explanation / route_plan / food_recommend / hotel_recommend
  createTime: number = Date.now()

  static fromJson(json: Record<string, Object>): Favorite {
    let fav = new Favorite()
    fav.id = json['id'] as number ?? 0
    fav.messageId = json['message_id'] as number ?? 0
    fav.conversationId = json['conversation_id'] as number ?? 0
    fav.content = json['content'] as string ?? ''
    fav.type = json['type'] as string ?? ''
    fav.createTime = json['create_time'] as number ?? Date.now()
    return fav
  }
}

// ==================== 行程模型 ====================

export class TripItem {
  id: number = 0
  title: string = ''
  dayIndex: number = 0
  sortOrder: number = 0
  content: string = ''       // JSON格式的行程详情
  city: string = ''
  duration: number = 0       // 行程天数
  createTime: number = Date.now()
  updateTime: number = Date.now()

  static fromJson(json: Record<string, Object>): TripItem {
    let trip = new TripItem()
    trip.id = json['id'] as number ?? 0
    trip.title = json['title'] as string ?? ''
    trip.dayIndex = json['day_index'] as number ?? 0
    trip.sortOrder = json['sort_order'] as number ?? 0
    trip.content = json['content'] as string ?? ''
    trip.city = json['city'] as string ?? ''
    trip.duration = json['duration'] as number ?? 0
    trip.createTime = json['create_time'] as number ?? Date.now()
    trip.updateTime = json['update_time'] as number ?? Date.now()
    return trip
  }
}

// ==================== 景点模型 ====================

export class ScenicSpot {
  id: number = 0
  name: string = ''
  category: string = ''
  city: string = ''
  description: string = ''
  imageUrl: string = ''
  address: string = ''
  rating: number = 0
  createTime: number = Date.now()

  static fromJson(json: Record<string, Object>): ScenicSpot {
    let spot = new ScenicSpot()
    spot.id = json['id'] as number ?? 0
    spot.name = json['name'] as string ?? ''
    spot.category = json['category'] as string ?? ''
    spot.city = json['city'] as string ?? ''
    spot.description = json['description'] as string ?? ''
    spot.imageUrl = json['image_url'] as string ?? ''
    spot.address = json['address'] as string ?? ''
    spot.rating = json['rating'] as number ?? 0
    spot.createTime = json['create_time'] as number ?? Date.now()
    return spot
  }
}

// ==================== 天气模型 ====================

export class WeatherInfo {
  city: string = ''
  weather: string = ''
  temperature: string = ''
  windDirection: string = ''
  windPower: string = ''
  humidity: string = ''
  reportTime: string = ''
  forecast: WeatherForecast[] = []
}

export class WeatherForecast {
  date: string = ''
  week: string = ''
  dayWeather: string = ''
  nightWeather: string = ''
  dayTemp: string = ''
  nightTemp: string = ''
  dayWind: string = ''
  nightWind: string = ''
  dayPower: string = ''
  nightPower: string = ''
}