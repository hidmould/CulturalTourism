/**
 * 天气服务 - 高德天气API + 大模型出行建议
 */
import { HttpClient } from '../network/HttpClient'
import { AMAP_WEATHER_KEY, AMAP_WEATHER_URL } from '../common/Constants'
import { WeatherInfo, WeatherForecast } from '../model/Models'

export class WeatherService {
  private static instance: WeatherService

  static getInstance(): WeatherService {
    if (!WeatherService.instance) {
      WeatherService.instance = new WeatherService()
    }
    return WeatherService.instance
  }

  /**
   * 查询城市天气
   * @param city 城市名称（中文）
   * @param extensions base=实况天气, all=预报天气
   */
  async getWeather(city: string, extensions: string = 'all'): Promise<WeatherInfo> {
    let url = `${AMAP_WEATHER_URL}?key=${AMAP_WEATHER_KEY}&city=${encodeURI(city)}&extensions=${extensions}`
    let response = await HttpClient.getInstance().get(url)
    let json = JSON.parse(response) as Record<string, Object>

    if (json['status'] !== '1') {
      throw new Error(`天气查询失败: ${json['info']}`)
    }

    let weatherInfo = new WeatherInfo()
    let lives = json['lives'] as Object[]
    let forecasts = json['forecasts'] as Object[]

    // 实况天气
    if (lives && lives.length > 0) {
      let live = lives[0] as Record<string, Object>
      weatherInfo.city = live['city'] as string ?? city
      weatherInfo.weather = live['weather'] as string ?? ''
      weatherInfo.temperature = live['temperature'] as string ?? ''
      weatherInfo.windDirection = live['winddirection'] as string ?? ''
      weatherInfo.windPower = live['windpower'] as string ?? ''
      weatherInfo.humidity = live['humidity'] as string ?? ''
      weatherInfo.reportTime = live['reporttime'] as string ?? ''
    }

    // 预报天气
    if (forecasts && forecasts.length > 0) {
      let forecast = forecasts[0] as Record<string, Object>
      weatherInfo.city = forecast['city'] as string ?? weatherInfo.city
      let casts = forecast['casts'] as Object[]
      if (casts) {
        for (let cast of casts) {
          let c = cast as Record<string, Object>
          let wf = new WeatherForecast()
          wf.date = c['date'] as string ?? ''
          wf.week = c['week'] as string ?? ''
          wf.dayWeather = c['dayweather'] as string ?? ''
          wf.nightWeather = c['nightweather'] as string ?? ''
          wf.dayTemp = c['daytemp'] as string ?? ''
          wf.nightTemp = c['nighttemp'] as string ?? ''
          wf.dayWind = c['daywind'] as string ?? ''
          wf.nightWind = c['nightwind'] as string ?? ''
          wf.dayPower = c['daypower'] as string ?? ''
          wf.nightPower = c['nightpower'] as string ?? ''
          weatherInfo.forecast.push(wf)
        }
      }
    }

    return weatherInfo
  }

  /**
   * 格式化天气信息为文本，供大模型使用
   */
  formatWeatherForAI(weatherInfo: WeatherInfo): string {
    let text = `当前城市：${weatherInfo.city}\n`
    text += `今日天气：${weatherInfo.weather}，温度${weatherInfo.temperature}°C，`
    text += `${weatherInfo.windDirection}风${weatherInfo.windPower}级，湿度${weatherInfo.humidity}%\n`

    if (weatherInfo.forecast.length > 0) {
      text += `\n未来天气预报：\n`
      for (let f of weatherInfo.forecast) {
        text += `${f.date} ${f.week}：${f.dayWeather} ${f.dayTemp}°C ~ ${f.nightTemp}°C\n`
      }
    }
    return text
  }
}