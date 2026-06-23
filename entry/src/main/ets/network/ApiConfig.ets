/**
 * API 配置
 * 集中管理所有API端点和密钥
 */
export class ApiConfig {
  // ========== DeepSeek 大模型配置 ==========
  // 通用大模型
  static readonly DEEPSEEK_GENERAL_URL: string = 'https://api.deepseek.com/v1/chat/completions'
  static readonly DEEPSEEK_GENERAL_KEY: string = ''  // 后续填入Key
  static readonly DEEPSEEK_GENERAL_MODEL: string = 'deepseek-chat'

  // 旅游专用模型
  static readonly DEEPSEEK_TRAVEL_URL: string = 'https://api.deepseek.com/v1/chat/completions'
  static readonly DEEPSEEK_TRAVEL_KEY: string = ''   // 后续填入Key
  static readonly DEEPSEEK_TRAVEL_MODEL: string = 'deepseek-reasoner'

  // ========== 天气API配置（使用和风天气或高德） ==========
  static readonly WEATHER_API_URL: string = 'https://restapi.amap.com/v3/weather/weatherInfo'
  static readonly WEATHER_API_KEY: string = ''        // 后续填入Key

  // 实时天气
  static getWeatherUrl(city: string): string {
    return `${ApiConfig.WEATHER_API_URL}?key=${ApiConfig.WEATHER_API_KEY}&city=${encodeURIComponent(city)}&extensions=all`
  }

  // ========== 请求超时 ==========
  static readonly HTTP_TIMEOUT: number = 30000        // 30秒
  static readonly SSE_TIMEOUT: number = 60000         // 60秒
}

/**
 * 系统提示词配置
 */
export class SystemPrompts {
  // 通用对话提示词
  static readonly GENERAL: string = `你是一个专业的智慧文旅助手，名为"文旅小智"。你可以帮助用户：
1. 景点讲解：介绍各地知名景点的历史、文化、特色
2. 游玩路线规划：根据用户需求规划合理的游玩路线
3. 特色美食推荐：推荐当地特色美食和餐厅
4. 住宿推荐：推荐合适的酒店和民宿
5. 天气穿搭建议：根据天气给出穿衣和出行建议

请用热情、专业、友好的语气回答，回答简洁明了。`

  // 旅游专用提示词
  static readonly TRAVEL: string = `你是一个资深的旅游规划专家，专注于为用户提供深度的旅游服务：
1. 详细的景点讲解，包括历史背景、文化内涵、游览攻略
2. 个性化的游玩路线规划，考虑交通、时间、体力等因素
3. 地道的美食推荐，从街头小吃到高端餐厅
4. 住宿推荐，根据预算和位置推荐
5. 结合天气的穿搭和出行建议
6. 可以生成结构化的行程计划JSON供用户使用

请以专业导游的口吻回答，提供的建议要具体、可操作。`
}