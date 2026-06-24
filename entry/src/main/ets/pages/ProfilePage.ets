/**
 * 个人信息编辑页面
 */
import { router } from '@kit.ArkUI'
import { UserService } from '../service/UserService'
import { UserInfo } from '../model/Models'
import { TravelPreference } from '../common/Constants'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct ProfilePage {
  @State userInfo: UserInfo = new UserInfo()
  @State nickname: string = ''
  @State travelPreference: string = ''
  @State residentCity: string = ''
  @State showPrefPicker: boolean = false
  @State isLoading: boolean = false

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
          Text(this.nickname ? this.nickname.substring(0, 1) : '?')
            .fontSize(36)
            .fontColor('#FFFFFF')
            .width(80)
            .height(80)
            .backgroundColor('#1E90FF')
            .borderRadius(40)
            .textAlign(TextAlign.Center)
          Text('点击更换头像')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 30, bottom: 20 })

        // 信息编辑区域
        Column() {
          this.buildEditItem('手机号', this.userInfo.phone, false)
          Divider().strokeWidth(0.5).color('#F0F0F0')
          this.buildEditItem('昵称', this.nickname, true, (value: string) => {
            this.nickname = value
          })
          Divider().strokeWidth(0.5).color('#F0F0F0')
          this.buildPickerItem('旅行偏好', this.travelPreference || '请选择', () => {
            this.showPrefPicker = true
          })
          Divider().strokeWidth(0.5).color('#F0F0F0')
          this.buildEditItem('常住城市', this.residentCity, true, (value: string) => {
            this.residentCity = value
          })
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
  buildPickerItem(label: string, value: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width(80)
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
      Text('→')
          .fontSize(16)
          .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(onClick)
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

  async saveProfile(): Promise<void> {
    try {
      let userService = UserService.getInstance()
      await userService.updateUserInfo('nickname', this.nickname)
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