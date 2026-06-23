import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { AuthService } from '../service/AuthService'
import { UserModel } from '../model/UserModel'

/**
 * 登录/注册页面
 * 支持：手机号+验证码登录、账号密码登录、记住密码
 */
@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State code: string = ''
  @State loginMode: number = 0       // 0: 验证码登录, 1: 密码登录
  @State rememberPassword: boolean = false
  @State isLoading: boolean = false
  @State codeText: string = '获取验证码'
  @State isCounting: boolean = false
  private authService: AuthService = AuthService.getInstance()
  private countdownTimer: number = -1

  aboutToAppear(): void {
    // 检查自动登录
    this.checkAutoLogin()
  }

  async checkAutoLogin(): Promise<void> {
    const user = await this.authService.autoLogin()
    if (user) {
      this.navigateToMain()
    }
  }

  build() {
    Column() {
      // 顶部Logo区域
      Column() {
        Text('🏯')
          .fontSize(60)
          .margin({ bottom: 12 })

        Text('智慧文旅')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Text('AI驱动的智慧旅游助手')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ top: 80, bottom: 40 })

      // 登录模式切换
      Row() {
        Text('验证码登录')
          .fontSize(16)
          .fontColor(this.loginMode === 0 ? '#007AFF' : '#999')
          .fontWeight(this.loginMode === 0 ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.loginMode = 0 })

        Text(' | ')
          .fontSize(16)
          .fontColor('#CCC')
          .margin({ left: 16, right: 16 })

        Text('密码登录')
          .fontSize(16)
          .fontColor(this.loginMode === 1 ? '#007AFF' : '#999')
          .fontWeight(this.loginMode === 1 ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.loginMode = 1 })
      }
      .margin({ bottom: 24 })

      // 手机号输入
      Row() {
        Text('+86')
          .fontSize(15)
          .fontColor('#333')
          .margin({ right: 8 })

        TextInput({ placeholder: '请输入手机号', text: this.phone })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .fontSize(15)
          .layoutWeight(1)
          .onChange((value: string) => { this.phone = value })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .border({ width: 1, color: '#E0E0E0', radius: 8 })
      .margin({ bottom: 16 })

      // 验证码模式
      if (this.loginMode === 0) {
        Row() {
          TextInput({ placeholder: '请输入验证码', text: this.code })
            .type(InputType.Number)
            .maxLength(6)
            .fontSize(15)
            .layoutWeight(1)
            .onChange((value: string) => { this.code = value })

          Text(this.codeText)
            .fontSize(13)
            .fontColor(this.isCounting ? '#999' : '#007AFF')
            .onClick(() => { this.sendCode() })
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .border({ width: 1, color: '#E0E0E0', radius: 8 })
        .margin({ bottom: 16 })
      }

      // 密码模式
      if (this.loginMode === 1) {
        TextInput({ placeholder: '请输入密码', text: this.password })
          .type(InputType.Password)
          .fontSize(15)
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .border({ width: 1, color: '#E0E0E0', radius: 8 })
          .margin({ bottom: 16 })
          .onChange((value: string) => { this.password = value })

        // 记住密码
        Row() {
          Checkbox({ name: 'remember', group: 'loginGroup' })
            .select(this.rememberPassword)
            .onChange((value: boolean) => { this.rememberPassword = value })

          Text('记住密码')
            .fontSize(13)
            .fontColor('#666')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ bottom: 16 })
      }

      // 登录按钮
      Button(this.isLoading ? '登录中...' : '登 录')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor('#FFF')
        .backgroundColor('#007AFF')
        .borderRadius(8)
        .enabled(!this.isLoading)
        .onClick(() => { this.handleLogin() })

      // 注册提示
      if (this.loginMode === 1) {
        Text('没有账号？点击登录将自动注册')
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 16 })
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .backgroundColor('#FFF')
  }

  /**
   * 发送验证码
   */
  sendCode(): void {
    if (this.isCounting) {
      return
    }
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' })
      return
    }
    // 模拟发送验证码
    promptAction.showToast({ message: '验证码已发送（测试码：123456）' })
    this.isCounting = true
    let countdown = 60
    this.codeText = `${countdown}s后重发`
    this.countdownTimer = setInterval(() => {
      countdown--
      if (countdown <= 0) {
        clearInterval(this.countdownTimer)
        this.isCounting = false
        this.codeText = '获取验证码'
      } else {
        this.codeText = `${countdown}s后重发`
      }
    }, 1000)
  }

  /**
   * 处理登录
   */
  async handleLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' })
      return
    }

    this.isLoading = true
    try {
      let user: UserModel | null = null
      if (this.loginMode === 0) {
        if (this.code.length === 0) {
          promptAction.showToast({ message: '请输入验证码' })
          this.isLoading = false
          return
        }
        user = await this.authService.loginByPhoneCode(this.phone, this.code)
      } else {
        if (this.password.length === 0) {
          promptAction.showToast({ message: '请输入密码' })
          this.isLoading = false
          return
        }
        user = await this.authService.loginByPassword(this.phone, this.password)
      }

      if (user) {
        promptAction.showToast({ message: '登录成功' })
        this.navigateToMain()
      }
    } catch (err) {
      promptAction.showToast({ message: `登录失败: ${err}` })
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 跳转到主页
   */
  navigateToMain(): void {
    router.replaceUrl({ url: 'pages/ChatListPage' })
  }
}