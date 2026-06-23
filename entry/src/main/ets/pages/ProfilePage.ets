import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { AuthService } from '../service/AuthService'
import { PreferencesHelper } from '../preferences/PreferencesHelper'
import { UserModel, TRAVEL_PREFERENCES } from '../model/UserModel'

/**
 * 个人信息页面
 * 用户信息、收藏列表、行程清单入口、设置
 */
@Entry
@Component
struct ProfilePage {
  @State user: UserModel = new UserModel()
  @State selectedPreference: string = '综合'
  @State showPreferencePicker: boolean = false
  private authService: AuthService = AuthService.getInstance()
  private prefsHelper: PreferencesHelper = PreferencesHelper.getInstance()

  async aboutToAppear(): Promise<void> {
    const user = await this.authService.getCurrentUser()
    if (user) {
      this.user = user
      this.selectedPreference = user.travelPreference || '综合'
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('‹')
            .fontSize(24)
            .fontColor('#007AFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .onClick(() => { router.back() })

        Text('个人信息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 8 })

      List() {
        // 头像和昵称
        ListItem() {
          Row() {
            Text('👤')
              .fontSize(40)
              .padding(12)
              .borderRadius(30)
              .backgroundColor('#E8F0FE')

            Column() {
              TextInput({ text: this.user.nickname })
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .backgroundColor(Color.Transparent)
                .onChange((value: string) => { this.user.nickname = value })

              Text(this.user.phone)
                .fontSize(13)
                .fontColor('#999')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
        }

        // 旅行偏好
        ListItem() {
          Row() {
            Text('旅行偏好')
              .fontSize(15)
              .fontColor('#333')

            Blank()

            Text(this.selectedPreference)
              .fontSize(14)
              .fontColor('#007AFF')

            Text('›')
              .fontSize(16)
              .fontColor('#CCC')
              .margin({ left: 4 })
          }
          .width('100%')
          .padding(16)
          .onClick(() => { this.showPreferencePicker = !this.showPreferencePicker })
        }

        if (this.showPreferencePicker) {
          ListItem() {
            Row() {
              ForEach(TRAVEL_PREFERENCES, (pref: string) => {
                Text(pref)
                  .fontSize(13)
                  .fontColor(pref === this.selectedPreference ? '#FFF' : '#007AFF')
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .backgroundColor(pref === this.selectedPreference ? '#007AFF' : '#E8F0FE')
                  .margin({ right: 8 })
                  .onClick(() => {
                    this.selectedPreference = pref
                    this.user.travelPreference = pref
                    this.authService.updateUserInfo(this.user)
                    this.showPreferencePicker = false
                  })
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 12 })
          }
        }

        // 常住城市
        ListItem() {
          Row() {
            Text('常住城市')
              .fontSize(15)
              .fontColor('#333')

            Blank()

            TextInput({ placeholder: '请输入城市', text: this.user.city })
              .fontSize(14)
              .fontColor('#666')
              .textAlign(TextAlign.End)
              .backgroundColor(Color.Transparent)
              .onChange((value: string) => {
                this.user.city = value
                this.authService.updateUserInfo(this.user)
              })
          }
          .width('100%')
          .padding(16)
        }

        // 分隔
        ListItem() {
          Divider().height(8).color('#F5F5F5')
        }

        // 我的收藏
        ListItem() {
          Row() {
            Text('⭐')
              .fontSize(20)
              .margin({ right: 12 })

            Column() {
              Text('我的收藏')
                .fontSize(15)
                .fontColor('#333')

              Text('查看收藏的攻略和景点')
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('›')
              .fontSize(16)
              .fontColor('#CCC')
          }
          .width('100%')
          .padding(16)
          .onClick(() => { router.pushUrl({ url: 'pages/FavoriteListPage' }) })
        }

        // 行程清单
        ListItem() {
          Row() {
            Text('📋')
              .fontSize(20)
              .margin({ right: 12 })

            Column() {
              Text('行程清单')
                .fontSize(15)
                .fontColor('#333')

              Text('管理您的旅行计划')
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('›')
              .fontSize(16)
              .fontColor('#CCC')
          }
          .width('100%')
          .padding(16)
          .onClick(() => { router.pushUrl({ url: 'pages/TripListPage' }) })
        }

        // 分隔
        ListItem() {
          Divider().height(8).color('#F5F5F5')
        }

        // 设置
        ListItem() {
          Row() {
            Text('🗑️')
              .fontSize(20)
              .margin({ right: 12 })

            Column() {
              Text('清除缓存')
                .fontSize(15)
                .fontColor('#333')

              Text('清除应用缓存数据')
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('›')
              .fontSize(16)
              .fontColor('#CCC')
          }
          .width('100%')
          .padding(16)
          .onClick(() => { this.clearCache() })
        }

        ListItem() {
          Row() {
            Text('ℹ️')
              .fontSize(20)
              .margin({ right: 12 })

            Column() {
              Text('关于应用')
                .fontSize(15)
                .fontColor('#333')

              Text('智慧文旅 v1.0.0')
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('›')
              .fontSize(16)
              .fontColor('#CCC')
          }
          .width('100%')
          .padding(16)
        }

        // 分隔
        ListItem() {
          Divider().height(8).color('#F5F5F5')
        }

        // 退出登录
        ListItem() {
          Button('退出登录')
            .width('90%')
            .height(44)
            .fontSize(15)
            .fontColor('#FF3B30')
            .backgroundColor('#FFF')
            .border({ width: 1, color: '#FF3B30', radius: 22 })
            .margin({ top: 16, bottom: 16 })
            .onClick(() => { this.logout() })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF')
  }

  async clearCache(): Promise<void> {
    await this.prefsHelper.clearAll()
    promptAction.showToast({ message: '缓存已清除' })
  }

  async logout(): Promise<void> {
    await this.authService.logout()
    router.replaceUrl({ url: 'pages/LoginPage' })
  }
}