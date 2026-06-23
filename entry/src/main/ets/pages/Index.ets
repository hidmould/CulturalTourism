import { router } from '@kit.ArkUI'
import { AuthService } from '../service/AuthService'

/**
 * 启动页 - 根据登录状态跳转
 */
@Entry
@Component
struct Index {
  private authService: AuthService = AuthService.getInstance()

  async aboutToAppear(): Promise<void> {
    const user = await this.authService.autoLogin()
    if (user) {
      router.replaceUrl({ url: 'pages/ChatListPage' })
    } else {
      router.replaceUrl({ url: 'pages/LoginPage' })
    }
  }

  build() {
    Column() {
      Text('🏯')
        .fontSize(60)
        .margin({ bottom: 16 })

      Text('智慧文旅')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')

      LoadingProgress()
        .width(30)
        .height(30)
        .margin({ top: 24 })
        .color('#007AFF')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFF')
  }
}