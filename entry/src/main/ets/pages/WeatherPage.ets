/**
 * 天气预告页面 - 高德天气 API 实时数据
 */
import { router } from '@kit.ArkUI'
import { WeatherService } from '../service/WeatherService'
import { WeatherInfo, WeatherForecast } from '../model/Models'
import { promptAction } from '@kit.ArkUI'

const DEFAULT_CITIES: string[] = ['北京', '上海', '广州', '深圳', '杭州', '成都', '武汉', '西安', '南京', '重庆', '长沙', '苏州']

@Entry
@Component
struct WeatherPage {
  @State city: string = '北京'
  @State searchCity: string = ''
  @State weatherInfo: WeatherInfo | null = null
  @State isLoading: boolean = false
  @State hasData: boolean = false
  @State showCityPicker: boolean = false
  @State currentDate: string = ''

  private weatherService: WeatherService = WeatherService.getInstance()
  private columns: number = 3
  private rows: number = Math.ceil(12 / 3) // DEFAULT_CITIES.length / columns

  aboutToAppear(): void {
    this.loadWeather()
  }

  async loadWeather(cityName?: string): Promise<void> {
    let targetCity = cityName ?? this.city
    if (!targetCity.trim()) {
      promptAction.showToast({ message: '请输入城市名称', duration: 1500 })
      return
    }

    this.isLoading = true
    try {
      let info = await this.weatherService.getWeather(targetCity, 'all')
      this.weatherInfo = info
      this.city = info.city || targetCity
      this.hasData = true
      this.currentDate = this.formatCurrentDate()
    } catch (err) {
      let error = err as Error
      promptAction.showToast({ message: `天气查询失败: ${error.message}`, duration: 2000 })
      this.hasData = false
    } finally {
      this.isLoading = false
    }
  }

  formatCurrentDate(): string {
    let now = new Date()
    let weekdays = ['日', '一', '二', '三', '四', '五', '六']
    return `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日 星期${weekdays[now.getDay()]}`
  }

  getWeatherIcon(weather: string): string {
    if (weather.includes('晴')) return '☀️'
    if (weather.includes('多云') || weather.includes('阴')) return '⛅'
    if (weather.includes('雨')) return '🌧️'
    if (weather.includes('雪')) return '❄️'
    if (weather.includes('雾') || weather.includes('霾')) return '🌫️'
    if (weather.includes('风')) return '💨'
    return '🌤️'
  }

  getWeekday(dateStr: string): string {
    let weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    let parts = dateStr.split('-')
    if (parts.length === 3) {
      let d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
      return weekdays[d.getDay()]
    }
    return ''
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => { router.back() })
        Text('天气预告')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 8 })
        Blank()
        Text('🌐 ' + this.city)
          .fontSize(12)
          .fontColor('#1E90FF')
          .backgroundColor('#E8F4FD')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick(() => { this.showCityPicker = true })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // 搜索城市
      Row() {
        TextInput({ placeholder: '输入城市名查询天气', text: this.searchCity })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .onChange((value: string) => { this.searchCity = value })
        Button('查询')
          .fontSize(13)
          .height(36)
          .backgroundColor('#1E90FF')
          .fontColor('#FFFFFF')
          .borderRadius(18)
          .margin({ left: 8 })
          .onClick(() => {
            if (this.searchCity.trim()) {
              this.city = this.searchCity.trim()
              this.loadWeather(this.city)
            } else {
              promptAction.showToast({ message: '请输入城市名称', duration: 1500 })
            }
          })
      }
      .width('94%')
      .margin({ top: 10 })

      Scroll() {
        Column() {
          if (this.isLoading) {
            LoadingProgress()
              .width(48)
              .height(48)
              .color('#1E90FF')
              .margin({ top: 80 })
            Text('正在获取天气数据...')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 12 })
          } else if (this.hasData && this.weatherInfo) {
            // 当前实况天气卡片
            this.buildCurrentWeather(this.weatherInfo)

            // 未来天气预报
            if (this.weatherInfo.forecast.length > 0) {
              this.buildForecastList(this.weatherInfo.forecast)
            }
          } else {
            Column() {
              Text('🌤️')
                .fontSize(64)
                .margin({ top: 80 })
              Text('输入城市名称查询天气')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 12 })
              Text('支持全国城市天气查询')
                .fontSize(12)
                .fontColor('#BBBBBB')
                .margin({ top: 4 })
            }
            .width('100%')
          }

          // 底部间距
          Divider().height(20).color(Color.Transparent)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#F0F4F8')

      // 城市选择弹窗
      if (this.showCityPicker) {
        this.buildCityPicker()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F4F8')
  }

  @Builder
  buildCurrentWeather(info: WeatherInfo) {
    Column() {
      // 日期
      Text(this.currentDate)
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .textAlign(TextAlign.Start)

      // 主要天气信息
      Row() {
        Text(this.getWeatherIcon(info.weather))
          .fontSize(56)
          .margin({ right: 12 })

        Column() {
          Text(info.weather || '--')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text(`${info.temperature}°C`)
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text('湿度')
            .fontSize(11)
            .fontColor('#999999')
          Text(`${info.humidity}%`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1E90FF')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 8 })

        Column() {
          Text('风力')
            .fontSize(11)
            .fontColor('#999999')
          Text(`${info.windPower}级`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 16 })
      }
      .width('100%')
      .margin({ top: 12 })
      .padding({ left: 4 })

      // 风向
      Row() {
        Text('风向: ')
          .fontSize(12)
          .fontColor('#999999')
        Text(info.windDirection || '--')
          .fontSize(13)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('数据来源: 高德地图')
          .fontSize(10)
          .fontColor('#BBBBBB')
      }
      .width('100%')
      .margin({ top: 12 })

      // 昨日温差参考（取预报第一天的数据）
      if (info.forecast.length > 0) {
        Row() {
          Text('☀️ 白天: ')
            .fontSize(12)
            .fontColor('#FF8800')
          Text(`${info.forecast[0].dayTemp}°C  ${info.forecast[0].dayWeather}  ${info.forecast[0].dayWind}风`)
            .fontSize(12)
            .fontColor('#333333')
          Blank()
          Text('🌙 夜间: ')
            .fontSize(12)
            .fontColor('#666666')
          Text(`${info.forecast[0].nightTemp}°C  ${info.forecast[0].nightWeather}`)
            .fontSize(12)
            .fontColor('#333333')
        }
        .width('100%')
        .margin({ top: 8 })
        .padding({ top: 8 })
        .border({ width: 0.5, color: '#E0E0E0' })
      }
    }
    .width('94%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 12 })
    .shadow({ radius: 6, color: '#15000000', offsetY: 3 })
  }

  @Builder
  buildForecastList(forecasts: WeatherForecast[]) {
    Column() {
      Text('未来天气预报')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 12 })

      ForEach(forecasts, (forecast: WeatherForecast, index: number) => {
        Row() {
          // 日期
          Column() {
            Text(forecast.date ? forecast.date.substring(5) : '')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text(this.getWeekday(forecast.date))
              .fontSize(11)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .width(50)
          .alignItems(HorizontalAlign.Center)

          // 天气图标
          Text(this.getWeatherIcon(forecast.dayWeather))
            .fontSize(24)
            .margin({ left: 8 })

          // 白天天气
          Text(forecast.dayWeather)
            .fontSize(12)
            .fontColor('#FF8800')
            .width(40)
            .textAlign(TextAlign.Center)
            .margin({ left: 4 })

          // 温度范围
          Text(`${forecast.nightTemp}° ~ ${forecast.dayTemp}°`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 风力
          Text(`${forecast.dayWind} ${forecast.dayPower}级`)
            .fontSize(11)
            .fontColor('#999999')
            .width(60)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 10, bottom: 10 })
        .backgroundColor(index === 0 ? '#F0F8FF' : '#FFFFFF')
        .borderRadius(8)
        .margin({ bottom: 6 })
      })
    }
    .width('94%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 12 })
    .shadow({ radius: 6, color: '#15000000', offsetY: 3 })
  }

  @Builder
  buildCityPicker() {
    Column() {
      Column() {
        Text('选择城市')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding(16)
          .textAlign(TextAlign.Center)

        // 热门城市列表
        Row({ space: 8 }) {
          Text('热门城市:')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 16 })
          Blank()
        }
        .width('100%')

        // 城市网格
        ForEach(this.range(this.rows), (row: number) => {
          Row({ space: 8 }) {
            ForEach(this.range(this.columns), (col: number) => {
              if (row * this.columns + col < DEFAULT_CITIES.length) {
                Button(DEFAULT_CITIES[row * this.columns + col])
                  .fontSize(12)
                  .height(32)
                  .backgroundColor(this.city === DEFAULT_CITIES[row * this.columns + col] ? '#1E90FF' : '#F5F5F5')
                  .fontColor(this.city === DEFAULT_CITIES[row * this.columns + col] ? '#FFFFFF' : '#333333')
                  .borderRadius(16)
                  .layoutWeight(1)
                  .onClick(() => {
                    let name = DEFAULT_CITIES[row * this.columns + col]
                    this.city = name
                    this.showCityPicker = false
                    this.loadWeather(name)
                  })
              } else {
                Text('')
                  .layoutWeight(1)
              }
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        })

        Button('取消')
          .width('90%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .borderRadius(20)
          .margin({ top: 12, bottom: 16 })
          .onClick(() => { this.showCityPicker = false })
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showCityPicker = false })
  }

  private range(n: number): number[] {
    let arr: number[] = []
    for (let i = 0; i < n; i++) {
      arr.push(i)
    }
    return arr
  }
}