/**
 * 登录页面 - 手机号+验证码登录 / 账号密码登录
 */
import { router } from '@kit.ArkUI'
import { UserService } from '../service/UserService'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State code: string = ''
  @State isCodeLogin: boolean = true
  @State rememberPassword: boolean = false
  @State codeText: string = '获取验证码'
  @State codeCountdown: number = 0
  @State isLoading: boolean = false
  private timer: number = -1

  aboutToAppear(): void {
    this.loadRememberState()
  }

  async loadRememberState(): Promise<void> {
    let userService = UserService.getInstance()
    let phone = await userService.getPhone()
    let remember = await userService.getRememberState()
    if (phone && remember) {
      this.phone = phone
      this.rememberPassword = true
      let pwd = await userService.getRememberedPassword()
      if (pwd) {
        this.password = pwd
      }
    }
  }

  build() {
    Column() {
      // 顶部装饰
      Column() {
        Text('智慧文旅')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 40 })
        Text('AI 驱动的智能旅行助手')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .opacity(0.8)
          .margin({ top: 8 })
      }
      .width('100%')
      .height(180)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#1E90FF')
      .borderRadius({ bottomLeft: 30, bottomRight: 30 })

      // 登录表单
      Column() {
        // 切换登录方式
        Row() {
          Text('验证码登录')
            .fontSize(16)
            .fontColor(this.isCodeLogin ? '#1E90FF' : '#999999')
            .fontWeight(this.isCodeLogin ? FontWeight.Bold : FontWeight.Normal)
            .onClick(() => { this.isCodeLogin = true })
          Text(' | ')
            .fontSize(16)
            .fontColor('#DDDDDD')
          Text('密码登录')
            .fontSize(16)
            .fontColor(!this.isCodeLogin ? '#1E90FF' : '#999999')
            .fontWeight(!this.isCodeLogin ? FontWeight.Bold : FontWeight.Normal)
            .onClick(() => { this.isCodeLogin = false })
        }
        .margin({ top: 30, bottom: 20 })

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

        if (this.isCodeLogin) {
          // 验证码输入
          Row() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .margin({ left: 12, right: 8 })
            TextInput({ placeholder: '请输入验证码', text: this.code })
              .type(InputType.Number)
              .maxLength(6)
              .layoutWeight(1)
              .height(48)
              .backgroundColor(Color.Transparent)
              .onChange((value: string) => { this.code = value })
            Button(this.codeText)
              .fontSize(12)
              .height(36)
              .backgroundColor(this.codeCountdown > 0 ? '#CCCCCC' : '#1E90FF')
              .borderRadius(18)
              .margin({ right: 6 })
              .enabled(this.codeCountdown === 0)
              .onClick(() => { this.sendCode() })
          }
          .width('100%')
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(24)
          .margin({ top: 16 })
        } else {
          // 密码输入
          Row() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .margin({ left: 12, right: 8 })
            TextInput({ placeholder: '请输入密码', text: this.password })
              .type(InputType.Password)
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

          // 记住密码
          Row() {
            Checkbox({ name: 'remember', group: 'loginGroup' })
              .select(this.rememberPassword)
              .selectedColor('#1E90FF')
              .onChange((value: boolean) => { this.rememberPassword = value })
            Text('记住密码')
              .fontSize(13)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .width('100%')
          .margin({ top: 12 })
        }

        // 登录按钮
        Button('登录')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#1E90FF')
          .borderRadius(24)
          .margin({ top: 30 })
          .enabled(!this.isLoading)
          .onClick(() => { this.doLogin() })

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

      Text('登录即表示同意《用户协议》和《隐私政策》')
        .fontSize(11)
        .fontColor('#999999')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 发送验证码
   */
  sendCode(): void {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 })
      return
    }
    // 模拟发送验证码
    this.codeCountdown = 60
    this.codeText = '60s'
    promptAction.showToast({ message: '验证码已发送（模拟：123456）', duration: 2000 })

    this.timer = setInterval(() => {
      this.codeCountdown--
      if (this.codeCountdown <= 0) {
        clearInterval(this.timer)
        this.codeText = '获取验证码'
      } else {
        this.codeText = `${this.codeCountdown}s`
      }
    }, 1000)
  }

  /**
   * 执行登录
   */
  async doLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 })
      return
    }

    this.isLoading = true
    try {
      let userService = UserService.getInstance()
      if (this.isCodeLogin) {
        if (this.code.length === 0) {
          promptAction.showToast({ message: '请输入验证码', duration: 2000 })
          this.isLoading = false
          return
        }
        await userService.loginByPhone(this.phone, this.code)
      } else {
        if (this.password.length === 0) {
          promptAction.showToast({ message: '请输入密码', duration: 2000 })
          this.isLoading = false
          return
        }
        await userService.loginByPassword(this.phone, this.password, this.rememberPassword)
      }

      promptAction.showToast({ message: '登录成功', duration: 1500 })
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