/**
 * 启动页 - 检查登录状态，自动跳转
 */
import { router } from '@kit.ArkUI'
import { UserService } from '../service/UserService'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { common } from '@kit.AbilityKit'

@Entry
@Component
struct Index {
  @State splashText: string = '智慧文旅'
  @State isReady: boolean = false

  aboutToAppear(): void {
    this.initApp()
  }

  async initApp(): Promise<void> {
    try {
      let context = getContext(this) as common.UIAbilityContext

      // 初始化数据库
      DatabaseHelper.getInstance().init(context)
      await DatabaseHelper.getInstance().getStore()

      // 初始化服务
      UserService.getInstance().init(context)

      // 检查自动登录
      let autoLogin = await UserService.getInstance().autoLogin()

      this.isReady = true

      setTimeout(() => {
        if (autoLogin) {
          router.replaceUrl({ url: 'pages/MainPage' })
        } else {
          router.replaceUrl({ url: 'pages/LoginPage' })
        }
      }, 800)
    } catch (err) {
      console.error('初始化失败: ' + JSON.stringify(err))
      this.isReady = true
      setTimeout(() => {
        router.replaceUrl({ url: 'pages/LoginPage' })
      }, 800)
    }
  }

  build() {
    Column() {
      Column() {
        Text('智慧文旅')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('AI 驱动的智能旅行助手')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .opacity(0.8)
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#1E90FF')

      Text('v1.0.0')
        .fontSize(12)
        .fontColor('#FFFFFF')
        .opacity(0.5)
        .margin({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1E90FF')
  }
}