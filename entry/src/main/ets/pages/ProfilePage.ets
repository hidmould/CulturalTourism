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
  @State isLoading: boolean = false
  private avatarColors: string[] = ['#1E90FF', '#FF6B6B', '#4ECDC4', '#FFD93D', '#6C5CE7', '#FF8A5C', '#A8E6CF', '#FF69B4']

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

      // 头像选择器
      if (this.showAvatarPicker) {
        this.buildAvatarPicker()
      }

      // 颜色选择器
      if (this.showColorPicker) {
        this.buildColorPicker()
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