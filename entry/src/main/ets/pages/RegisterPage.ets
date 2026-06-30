/**
 * 注册页面 - 手机号+密码+昵称注册
 */
import { router } from '@kit.ArkUI'
import { UserService } from '../service/UserService'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct RegisterPage {
  @State phone: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State nickname: string = ''
  @State isLoading: boolean = false

  build() {
    Column() {
      // 顶部装饰
      Column() {
        Text('创建账号')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
           .fontColor('#FFFFFF')
          .margin({ top: 40 })
        Text('注册智慧文旅，开启智能旅行')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .opacity(0.8)
          .margin({ top: 8 })
      }
      .width('100%')
      .height(160)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#1E90FF')
      .borderRadius({ bottomLeft: 30, bottomRight: 30 })

      // 注册表单
      Column() {
        // 手机号输入
        Row() {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .margin({ left: 12, right: 8 })
          TextInput({ placeholder: '请输入手机号', text: this.phone })
            .type(InputType.PhoneNumber)
            .maxLength(11)
            .layoutWeight(1)
            .height(48)
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => { this.phone = value })
        }
        .width('100%')
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(24)
        .margin({ top: 30 })

        // 昵称输入
        Row() {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .margin({ left: 12, right: 8 })
          TextInput({ placeholder: '请输入昵称（选填）', text: this.nickname })
            .maxLength(20)
            .layoutWeight(1)
            .height(48)
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => { this.nickname = value })
        }
        .width('100%')
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(24)
        .margin({ top: 16 })

        // 密码输入
        Row() {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .margin({ left: 12, right: 8 })
          TextInput({ placeholder: '请设置密码（6-16位）', text: this.password })
            .type(InputType.Password)
            .maxLength(16)
            .layoutWeight(1)
            .height(48)
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => { this.password = value })
        }
        .width('100%')
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(24)
        .margin({ top: 16 })

        // 确认密码输入
        Row() {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .margin({ left: 12, right: 8 })
          TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
            .type(InputType.Password)
            .maxLength(16)
            .layoutWeight(1)
            .height(48)
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => { this.confirmPassword = value })
        }
        .width('100%')
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(24)
        .margin({ top: 16 })

        // 注册按钮
        Button('注册')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#1E90FF')
          .borderRadius(24)
          .margin({ top: 30 })
          .enabled(!this.isLoading)
          .onClick(() => { this.doRegister() })

        // 加载状态
        if (this.isLoading) {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#1E90FF')
            .margin({ top: 16 })
        }
      }
      .width('90%')
      .padding({ left: 20, right: 20 })

      Blank()

      // 底部：已有账号，去登录
      Row() {
        Text('已有账号？')
          .fontSize(13)
          .fontColor('#999999')
        Text('去登录')
          .fontSize(13)
          .fontColor('#1E90FF')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            router.back()
          })
      }
      .margin({ bottom: 30 })

      Text('注册即表示同意《用户协议》和《隐私政策》')
        .fontSize(11)
        .fontColor('#999999')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 执行注册
   */
  async doRegister(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 })
      return
    }
    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码至少6位', duration: 2000 })
      return
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次密码不一致', duration: 2000 })
      return
    }

    this.isLoading = true
    try {
      let userService = UserService.getInstance()
      await userService.register(this.phone, this.password, this.nickname)

      promptAction.showToast({ message: '注册成功', duration: 1500 })
      setTimeout(() => {
        router.replaceUrl({ url: 'pages/MainPage' })
      }, 500)
    } catch (err) {
      let error = err as Error
      promptAction.showToast({ message: error.message, duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }
}