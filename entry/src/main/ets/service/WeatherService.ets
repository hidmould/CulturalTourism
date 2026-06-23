import { HttpClient } from '../network/HttpClient'
import { ApiConfig } from '../network/ApiConfig'

/**
 * 天气数据接口返回
 */
export interface WeatherData {
  city: string
  temperature: string
  weather: string
  humidity: string
  windDirection: string
  windPower: string
  reportTime: string
  forecasts: WeatherForecast[]
}

export interface WeatherForecast {
  date: string
  dayWeather: string
  nightWeather: string
  dayTemp: string
  nightTemp: string
  dayWind: string
  nightWind: string
}

/**
 * 天气服务
 * 查询实时天气和预报
 */
export class WeatherService {
  private static instance: WeatherService
  private httpClient: HttpClient = HttpClient.getInstance()

  static getInstance(): WeatherService {
    if (!WeatherService.instance) {
      WeatherService.instance = new WeatherService()
    }
    return WeatherService.instance
  }

  /**
   * 查询城市天气
   */
  async getWeather(city: string): Promise<WeatherData | null> {
    try {
      const url = ApiConfig.getWeatherUrl(city)
      const result = await this.httpClient.get(url)

      const data = JSON.parse(result)
      if (data.status === '1' && data.lives && data.lives.length > 0) {
        const live = data.lives[0]
        const forecasts = data.forecasts && data.forecasts.length > 0
          ? this.parseForecasts(data.forecasts[0].casts)
          : []

        return {
          city: live.city,
          temperature: live.temperature,
          weather: live.weather,
          humidity: live.humidity,
          windDirection: live.winddirection,
          windPower: live.windpower,
          reportTime: live.reporttime,
          forecasts: forecasts
        }
      }

      return null
    } catch (_err) {
      return null
    }
  }

  /**
   * 解析预报数据
   */
  private parseForecasts(casts: Array<Record<string, string>>): WeatherForecast[] {
    return casts.map((cast: Record<string, string>) => ({
      date: cast['date'] || '',
      dayWeather: cast['dayweather'] || '',
      nightWeather: cast['nightweather'] || '',
      dayTemp: cast['daytemp'] || '',
      nightTemp: cast['nighttemp'] || '',
      dayWind: cast['daywind'] || '',
      nightWind: cast['nightwind'] || ''
    }))
  }

  /**
   * 获取模拟天气数据（开发测试用）
   */
  getMockWeather(city: string): WeatherData {
    return {
      city: city,
      temperature: '25',
      weather: '晴',
      humidity: '55',
      windDirection: '东南',
      windPower: '3',
      reportTime: new Date().toISOString(),
      forecasts: [
        { date: '2026-06-24', dayWeather: '晴', nightWeather: '多云', dayTemp: '28', nightTemp: '20', dayWind: '东南风3级', nightWind: '东风2级' },
        { date: '2026-06-25', dayWeather: '多云', nightWeather: '阴', dayTemp: '26', nightTemp: '19', dayWind: '东北风3级', nightWind: '北风2级' },
        { date: '2026-06-26', dayWeather: '小雨', nightWeather: '阴', dayTemp: '24', nightTemp: '18', dayWind: '北风4级', nightWind: '北风3级' }
      ]
    }
  }
}