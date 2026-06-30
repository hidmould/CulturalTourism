/**
 * 个人信息编辑页面
 */
import { router } from '@kit.ArkUI'
import { UserService } from '../service/UserService'
import { UserInfo } from '../model/Models'
import { TravelPreference } from '../common/Constants'
import { promptAction } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { geolocation } from '@kit.LocationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'

@Entry
@Component
struct ProfilePage {
  @State userInfo: UserInfo = new UserInfo()
  @State nickname: string = ''
  @State travelPreference: string = ''
  @State residentCity: string = ''
  @State avatar: string = ''
  @State showPrefPicker: boolean = false
  @State showAvatarPicker: boolean = false
  @State showColorPicker: boolean = false
  @State showCityPicker: boolean = false
  @State citySearchKeyword: string = ''
  @State isLoading: boolean = false
  private avatarColors: string[] = ['#1E90FF', '#FF6B6B', '#4ECDC4', '#FFD93D', '#6C5CE7', '#FF8A5C', '#A8E6CF', '#FF69B4']

  // 城市列表：热门城市 + 按省份分组
  private hotCities: string[] = ['北京', '上海', '广州', '深圳', '杭州', '成都', '重庆', '武汉', '西安', '南京', '苏州', '长沙']
  private cityGroups: Record<string, string[]> = {
    '直辖市': ['北京', '上海', '天津', '重庆'],
    '华东': ['南京', '苏州', '杭州', '宁波', '合肥', '福州', '厦门', '南昌', '济南', '青岛'],
    '华南': ['广州', '深圳', '珠海', '东莞', '佛山', '南宁', '桂林', '海口', '三亚'],
    '华中': ['武汉', '长沙', '郑州', '洛阳', '开封'],
    '华北': ['石家庄', '太原', '呼和浩特', '保定'],
    '西北': ['西安', '兰州', '西宁', '银川', '乌鲁木齐', '敦煌'],
    '西南': ['成都', '重庆', '贵阳', '昆明', '丽江', '大理', '拉萨', '日喀则'],
    '东北': ['哈尔滨', '长春', '沈阳', '大连', '吉林', '延边'],
    '港澳台': ['香港', '澳门', '台北', '高雄', '台中']
  }

  aboutToAppear(): void {
    this.loadUserInfo()
  }

  async loadUserInfo(): Promise<void> {
    this.isLoading = true
    try {
      this.userInfo = await UserService.getInstance().getUserInfo()
      this.nickname = this.userInfo.nickname
      this.travelPreference = this.userInfo.travelPreference
      this.residentCity = this.userInfo.residentCity
      this.avatar = this.userInfo.avatar
    } catch (err) {
      console.error('加载用户信息失败')
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        Row() {
          Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => { router.back() })
          Text('个人信息')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ left: 8 })
          Blank()
          Text('保存')
            .fontSize(14)
            .fontColor('#1E90FF')
            .onClick(() => { this.saveProfile() })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')

        // 头像区域
        Column() {
          if (this.avatar && this.avatar.startsWith('file://')) {
            // 显示用户选择的图片头像
            Image(this.avatar)
              .width(80)
              .height(80)
              .borderRadius(40)
              .objectFit(ImageFit.Cover)
          } else {
            // 显示文字头像（使用自定义颜色或默认蓝色）
            Text(this.nickname ? this.nickname.substring(0, 1) : '?')
              .fontSize(36)
              .fontColor('#FFFFFF')
              .width(80)
              .height(80)
              .backgroundColor(this.avatar || '#1E90FF')
              .borderRadius(40)
              .textAlign(TextAlign.Center)
          }
          Text('点击更换头像')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 30, bottom: 20 })
        .onClick(() => { this.showAvatarPicker = true })

        // 信息编辑区域
        Column() {
          this.buildPhoneItem()
          Divider().strokeWidth(0.5).color('#F0F0F0')
          this.buildNicknameEdit()
          Divider().strokeWidth(0.5).color('#F0F0F0')
          this.buildTravelPrefPicker()
          Divider().strokeWidth(0.5).color('#F0F0F0')
          this.buildCityEdit()
        }
        .width('92%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      // 偏好选择器
      if (this.showPrefPicker) {
        this.buildPreferencePicker()
      }

      // 头像选择器
      if (this.showAvatarPicker) {
        this.buildAvatarPicker()
      }

      // 颜色选择器
      if (this.showColorPicker) {
        this.buildColorPicker()
      }

      // 城市选择器
      if (this.showCityPicker) {
        this.buildCityPicker()
      }
    }
  }

  @Builder
  buildEditItem(label: string, value: string, editable: boolean, onChange?: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width(80)
      if (editable) {
        TextInput({ text: value, placeholder: `请输入${label}` })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .onChange(onChange ?? (() => {}))
      } else {
        Text(value)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  buildPhoneItem() {
    Row() {
      Text('手机号')
        .fontSize(14)
        .fontColor('#666666')
        .width(80)
      Text(this.userInfo.phone)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  buildNicknameEdit() {
    Row() {
      Text('昵称')
        .fontSize(14)
        .fontColor('#666666')
        .width(80)
      TextInput({ text: this.nickname, placeholder: '请输入昵称' })
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .backgroundColor(Color.Transparent)
        .padding(0)
        .onChange((value: string) => {
          this.nickname = value
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  buildCityEdit() {
    Row() {
      Text('常住城市')
        .fontSize(14)
        .fontColor('#666666')
        .width(80)
      Text(this.residentCity || '请选择城市')
        .fontSize(14)
        .fontColor(this.residentCity ? '#333333' : '#CCCCCC')
        .layoutWeight(1)
      Text('→')
          .fontSize(16)
          .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      this.showCityPicker = true
    })
  }

  @Builder
  buildTravelPrefPicker() {
    Row() {
      Text('旅行偏好')
        .fontSize(14)
        .fontColor('#666666')
        .width(80)
      Text(this.travelPreference || '请选择')
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
      Text('→')
          .fontSize(16)
          .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      this.showPrefPicker = true
    })
  }

  private preferenceOptions: string[] = [TravelPreference.FAMILY, TravelPreference.SOLO, TravelPreference.FOOD, TravelPreference.ALL]

  @Builder
  buildPreferencePicker() {
    Column() {
      Column() {
        Text('选择旅行偏好')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding(16)
          .textAlign(TextAlign.Center)

        ForEach(this.preferenceOptions, (pref: string) => {
          Row() {
            Text(pref)
              .fontSize(14)
              .fontColor(this.travelPreference === pref ? '#1E90FF' : '#333333')
              .layoutWeight(1)
            if (this.travelPreference === pref) {
              Text('✓')
                .fontSize(18)
                .fontColor('#1E90FF')
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .onClick(() => {
            this.travelPreference = pref
            this.showPrefPicker = false
          })
        })

        Button('取消')
          .width('90%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .borderRadius(20)
          .margin({ top: 8, bottom: 16 })
          .onClick(() => { this.showPrefPicker = false })
      }
      .width('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showPrefPicker = false })
  }

  // ==================== 头像选择器 ====================

  @Builder
  buildAvatarPicker() {
    Column() {
      Column() {
        Text('更换头像')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding(16)
          .textAlign(TextAlign.Center)

        // 从相册选择
        Row() {
          Text('📷')
            .fontSize(20)
            .margin({ left: 16 })
          Text('从相册选择')
            .fontSize(15)
            .fontColor('#333333')
            .margin({ left: 12 })
        }
        .width('100%')
        .padding({ top: 14, bottom: 14 })
        .onClick(() => {
          this.showAvatarPicker = false
          this.pickFromGallery()
        })

        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 16, right: 16 })

        // 选择颜色
        Row() {
          Text('🎨')
            .fontSize(20)
            .margin({ left: 16 })
          Text('选择头像颜色')
            .fontSize(15)
            .fontColor('#333333')
            .margin({ left: 12 })
        }
        .width('100%')
        .padding({ top: 14, bottom: 14 })
        .onClick(() => {
          this.showAvatarPicker = false
          this.showColorPicker = true
        })

        Button('取消')
          .width('90%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .borderRadius(20)
          .margin({ top: 12, bottom: 16 })
          .onClick(() => { this.showAvatarPicker = false })
      }
      .width('80%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showAvatarPicker = false })
  }

  // ==================== 颜色选择器 ====================

  @Builder
  buildColorPicker() {
    Column() {
      Column() {
        Text('选择头像颜色')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding(16)
          .textAlign(TextAlign.Center)

        Grid() {
          ForEach(this.avatarColors, (color: string) => {
            GridItem() {
              Column() {
                Text(this.nickname ? this.nickname.substring(0, 1) : '?')
                  .fontSize(20)
                  .fontColor('#FFFFFF')
                  .width(44)
                  .height(44)
                  .backgroundColor(color)
                  .borderRadius(22)
                  .textAlign(TextAlign.Center)
              }
              .padding(8)
              .onClick(() => {
                this.avatar = color
                this.showColorPicker = false
              })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(12)
        .columnsGap(12)
        .width('90%')
        .padding({ top: 8, bottom: 16 })

        Button('取消')
          .width('90%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .borderRadius(20)
          .margin({ bottom: 16 })
          .onClick(() => { this.showColorPicker = false })
      }
      .width('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showColorPicker = false })
  }

  // ==================== 城市选择器 ====================

  // 获取所有城市（扁平化）
  private getAllCities(): string[] {
    let cities: string[] = []
    let cityNames = Object.keys(this.cityGroups)
    for (let i = 0; i < cityNames.length; i++) {
      let group = this.cityGroups[cityNames[i]]
      for (let j = 0; j < group.length; j++) {
        if (cities.indexOf(group[j]) === -1) {
          cities.push(group[j])
        }
      }
    }
    return cities
  }

  // 根据关键词搜索城市
  private getFilteredCities(): string[] {
    let keyword = this.citySearchKeyword.trim()
    if (keyword.length === 0) {
      return []
    }
    let allCities = this.getAllCities()
    let result: string[] = []
    for (let i = 0; i < allCities.length; i++) {
      if (allCities[i].indexOf(keyword) !== -1) {
        result.push(allCities[i])
      }
    }
    return result
  }

  @Builder
  buildCityPicker() {
    Column() {
      Column() {
        // 标题栏
        Row() {
          Text('选择城市')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Blank()
          Text('✕')
            .fontSize(18)
            .fontColor('#999999')
            .onClick(() => { this.showCityPicker = false })
        }
        .width('100%')
        .padding(16)

        // 搜索框
        Row() {
          Text('🔍')
            .fontSize(14)
            .margin({ left: 12 })
          TextInput({ text: this.citySearchKeyword, placeholder: '搜索城市名称' })
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .backgroundColor(Color.Transparent)
            .padding(0)
            .onChange((value: string) => {
              this.citySearchKeyword = value
            })
        }
        .width('92%')
        .height(36)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .margin({ bottom: 12 })

        // 自动定位按钮
        Button() {
          Row() {
            Text('')
              .fontSize(16)
            Text('自动定位')
              .fontSize(14)
              .margin({ left: 6 })
          }
        }
        .width('90%')
        .height(40)
        .fontSize(14)
        .backgroundColor('#E8F4FD')
        .fontColor('#1E90FF')
        .borderRadius(8)
        .margin({ bottom: 12 })
        .onClick(() => { this.locateCity() })

        // 城市列表 (可滚动)
        Scroll() {
          Column() {
            // 搜索结果
            if (this.citySearchKeyword.trim().length > 0) {
              Text(`搜索结果 (${this.getFilteredCities().length})`)
                .fontSize(13)
                .fontColor('#999999')
                .width('100%')
                .padding({ left: 16, top: 8, bottom: 8 })

              if (this.getFilteredCities().length === 0) {
                Text('未找到匹配城市')
                  .fontSize(14)
                  .fontColor('#CCCCCC')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 20, bottom: 20 })
              } else {
                Grid() {
                  ForEach(this.getFilteredCities(), (city: string) => {
                    GridItem() {
                      Text(city)
                        .fontSize(13)
                        .fontColor(this.residentCity === city ? '#1E90FF' : '#333333')
                        .backgroundColor(this.residentCity === city ? '#E8F4FD' : '#F5F5F5')
                        .borderRadius(6)
                        .width('100%')
                        .height(36)
                        .textAlign(TextAlign.Center)
                        .onClick(() => {
                          this.residentCity = city
                          this.citySearchKeyword = ''
                          this.showCityPicker = false
                        })
                    }
                  })
                }
                .columnsTemplate('1fr 1fr 1fr')
                .rowsGap(8)
                .columnsGap(8)
                .width('92%')
                .padding({ bottom: 12 })
              }
            } else {
              // 热门城市
              Text('热门城市')
                .fontSize(13)
                .fontColor('#999999')
                .width('100%')
                .padding({ left: 16, top: 8, bottom: 8 })

              Grid() {
                ForEach(this.hotCities, (city: string) => {
                  GridItem() {
                    Text(city)
                      .fontSize(13)
                      .fontColor(this.residentCity === city ? '#1E90FF' : '#333333')
                      .backgroundColor(this.residentCity === city ? '#E8F4FD' : '#F5F5F5')
                      .borderRadius(6)
                      .width('100%')
                      .height(36)
                      .textAlign(TextAlign.Center)
                      .onClick(() => {
                        this.residentCity = city
                        this.showCityPicker = false
                      })
                  }
                })
              }
              .columnsTemplate('1fr 1fr 1fr')
              .rowsGap(8)
              .columnsGap(8)
              .width('92%')
              .padding({ bottom: 12 })

              Divider().strokeWidth(0.5).color('#F0F0F0').width('92%')

              // 按区域分组
              ForEach(Object.keys(this.cityGroups), (groupName: string) => {
                Column() {
                  Text(groupName)
                    .fontSize(13)
                    .fontColor('#999999')
                    .width('100%')
                    .padding({ left: 16, top: 10, bottom: 8 })

                  Grid() {
                    ForEach(this.cityGroups[groupName], (city: string) => {
                      GridItem() {
                        Text(city)
                          .fontSize(13)
                          .fontColor(this.residentCity === city ? '#1E90FF' : '#333333')
                          .backgroundColor(this.residentCity === city ? '#E8F4FD' : '#F5F5F5')
                          .borderRadius(6)
                          .width('100%')
                          .height(36)
                          .textAlign(TextAlign.Center)
                          .onClick(() => {
                            this.residentCity = city
                            this.showCityPicker = false
                          })
                      }
                    })
                  }
                  .columnsTemplate('1fr 1fr 1fr')
                  .rowsGap(8)
                  .columnsGap(8)
                  .width('92%')
                  .padding({ bottom: 10 })
                }
                .width('100%')
              })
            }
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.End)
    .onClick(() => { this.showCityPicker = false })
  }

  // 自动定位
  async locateCity(): Promise<void> {
    promptAction.showToast({ message: '正在定位...', duration: 1000 })
    try {
      // 1. 动态申请定位权限
      let context = getContext(this) as common.UIAbilityContext
      let atManager = abilityAccessCtrl.createAtManager()
      let grantStatus = await atManager.requestPermissionsFromUser(context, [
        'ohos.permission.LOCATION',
        'ohos.permission.APPROXIMATELY_LOCATION'
      ])
      console.info(`[定位] 权限结果: ${JSON.stringify(grantStatus.authResults)}`)
      let granted = grantStatus.authResults.every((result: number) => result === 0)

      if (!granted) {
        promptAction.showToast({ message: '定位权限未授权，请手动选择城市', duration: 2000 })
        return
      }

      // 2. 获取定位（使用 FIRST_FIX 快速定位）
      let locationRequest: geolocation.LocationRequest = {
        priority: geolocation.LocationRequestPriority.FIRST_FIX,
        scenario: geolocation.LocationRequestScenario.UNSET
      }
      let location = await geolocation.getCurrentLocation(locationRequest)
      let lat = location.latitude
      let lng = location.longitude
      console.info(`[定位] 经纬度: ${lat}, ${lng}`)

      // 3. 根据经纬度匹配最近的城市
      let matchedCity = this.findNearestCity(lat, lng)
      if (matchedCity) {
        this.residentCity = matchedCity
        promptAction.showToast({ message: `定位成功：${matchedCity}`, duration: 1500 })
      } else {
        promptAction.showToast({ message: `定位成功，请从列表选择城市`, duration: 2000 })
      }
    } catch (err) {
      let error = err as BusinessError
      console.error(`[定位] 失败 code=${error.code}, message=${error.message}`)
      promptAction.showToast({ message: `定位失败(${error.code})，请手动选择`, duration: 2000 })
    }
  }

  // 根据经纬度匹配最近的城市（简化版：使用热门城市近似坐标）
  private cityCoordinates: Record<string, [number, number]> = {
    '北京': [39.9042, 116.4074],
    '上海': [31.2304, 121.4737],
    '广州': [23.1291, 113.2644],
    '深圳': [22.5431, 114.0579],
    '杭州': [30.2741, 120.1551],
    '成都': [30.5728, 104.0668],
    '重庆': [29.5630, 106.5516],
    '武汉': [30.5928, 114.3055],
    '西安': [34.3416, 108.9398],
    '南京': [32.0603, 118.7969],
    '苏州': [31.2989, 120.5853],
    '长沙': [28.2282, 112.9388],
    '天津': [39.3434, 117.3616],
    '宁波': [29.8683, 121.5440],
    '合肥': [31.8206, 117.2272],
    '福州': [26.0745, 119.2965],
    '厦门': [24.4798, 118.0894],
    '南昌': [28.6820, 115.8579],
    '济南': [36.6512, 117.1209],
    '青岛': [36.0671, 120.3826],
    '珠海': [22.2710, 113.5767],
    '东莞': [23.0209, 113.7518],
    '佛山': [23.0218, 113.1219],
    '南宁': [22.8170, 108.3669],
    '桂林': [25.2736, 110.2992],
    '海口': [20.0174, 110.3492],
    '三亚': [18.2528, 109.5119],
    '郑州': [34.7466, 113.6253],
    '洛阳': [34.6197, 112.4540],
    '开封': [34.7972, 114.3074],
    '石家庄': [38.0428, 114.5149],
    '太原': [37.8706, 112.5509],
    '呼和浩特': [40.8422, 111.7498],
    '兰州': [36.0611, 103.8343],
    '西宁': [36.6171, 101.7782],
    '银川': [38.4872, 106.2309],
    '乌鲁木齐': [43.8256, 87.6168],
    '敦煌': [40.1422, 94.6617],
    '贵阳': [26.6470, 106.6302],
    '昆明': [25.0389, 102.7183],
    '丽江': [26.8721, 100.2334],
    '大理': [25.6065, 100.2676],
    '拉萨': [29.6500, 91.1409],
    '哈尔滨': [45.8038, 126.5340],
    '长春': [43.8171, 125.3235],
    '沈阳': [41.8057, 123.4315],
    '大连': [38.9140, 121.6147],
    '香港': [22.3193, 114.1694],
    '澳门': [22.1987, 113.5439],
    '台北': [25.0330, 121.5654],
    '高雄': [22.6273, 120.3014]
  }

  private findNearestCity(lat: number, lng: number): string {
    let minDist = Infinity
    let nearestCity = ''
    let cityNames = Object.keys(this.cityCoordinates)
    for (let i = 0; i < cityNames.length; i++) {
      let city = cityNames[i]
      let coords = this.cityCoordinates[city]
      let cityLat = coords[0]
      let cityLng = coords[1]
      let dist = Math.sqrt(Math.pow(lat - cityLat, 2) + Math.pow(lng - cityLng, 2))
      if (dist < minDist) {
        minDist = dist
        nearestCity = city
      }
    }
    // 距离超过 3 度（约300km）认为不匹配
    return minDist < 3 ? nearestCity : ''
  }

  // ==================== 相册选择 ====================

  async pickFromGallery(): Promise<void> {
    try {
      let context = getContext(this) as common.UIAbilityContext
      let photoPicker = new photoAccessHelper.PhotoViewPicker()
      let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      photoSelectOptions.maxSelectNumber = 1

      let photoViewResult = await photoPicker.select(photoSelectOptions)
      if (photoViewResult.photoUris.length > 0) {
        let uri = photoViewResult.photoUris[0]
        // 复制图片到应用沙箱目录，确保持久访问
        let savedPath = await this.copyImageToSandbox(context, uri)
        this.avatar = savedPath
      }
    } catch (err) {
      let error = err as Error
      console.error('选择图片失败: ' + error.message)
      promptAction.showToast({ message: '选择图片失败', duration: 1500 })
    }
  }

  async copyImageToSandbox(context: common.UIAbilityContext, srcUri: string): Promise<string> {
    let file = await fileIo.open(srcUri, fileIo.OpenMode.READ_ONLY)
    let fileName = `avatar_${Date.now()}.jpg`
    let destPath = context.filesDir + '/' + fileName
    let destFile = await fileIo.open(destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
    let buf = new ArrayBuffer(4096)
    let readLen = 0
    while ((readLen = await fileIo.read(file.fd, buf)) > 0) {
      await fileIo.write(destFile.fd, buf.slice(0, readLen))
    }
    await fileIo.close(file)
    await fileIo.close(destFile)
    return 'file://' + destPath
  }

  // ==================== 保存 ====================

  async saveProfile(): Promise<void> {
    try {
      let userService = UserService.getInstance()
      await userService.updateUserInfo('nickname', this.nickname)
      if (this.avatar) {
        await userService.updateUserInfo('avatar', this.avatar)
      }
      if (this.travelPreference) {
        await userService.updateUserInfo('travelPreference', this.travelPreference)
      }
      if (this.residentCity) {
        await userService.updateUserInfo('residentCity', this.residentCity)
      }
      promptAction.showToast({ message: '保存成功', duration: 1500 })
      setTimeout(() => { router.back() }, 500)
    } catch (err) {
      promptAction.showToast({ message: '保存失败', duration: 1500 })
    }
  }
}