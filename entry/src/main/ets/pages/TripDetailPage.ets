/**
 * 行程清单管理页面
 */
import { router } from '@kit.ArkUI'
import { TripService } from '../service/TripService'
import { TripItem } from '../model/Models'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct TripDetailPage {
  @State trips: TripItem[] = []
  @State isLoading: boolean = false
  @State showAddDialog: boolean = false
  @State newTripTitle: string = ''
  @State newTripCity: string = ''
  @State newTripDays: number = 1
  @State expandedTripIds: number[] = []

  aboutToAppear(): void {
    this.loadTrips()
  }

  async loadTrips(): Promise<void> {
    this.isLoading = true
    try {
      this.trips = await TripService.getInstance().getAllTrips()
    } catch (err) {
      console.error('加载行程失败')
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
          Text('行程清单')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ left: 8 })
          Blank()
          Text('+')
          .fontSize(22)
          .fontColor('#1E90FF')
          .fontWeight(FontWeight.Bold)
          .onClick(() => { this.showAddDialog = true })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')

        // 行程列表
        if (this.isLoading) {
          LoadingProgress()
            .width(40)
            .height(40)
            .margin({ top: 100 })
        } else if (this.trips.length === 0) {
          Column() {
            Text('📝')
          .fontSize(40)
          .margin({ top: 80 })
            Text('暂无行程计划')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12 })
            Text('点击右上角 + 添加行程')
              .fontSize(12)
              .fontColor('#BBBBBB')
              .margin({ top: 4 })
          }
          .width('100%')
        } else {
          List() {
            ForEach(this.trips, (item: TripItem, index: number) => {
              ListItem() {
                this.buildTripItem(item, index)
              }
              .margin({ bottom: 8 })
              .swipeAction({ end: this.buildDeleteButton(item.id) })
            })
          }
          .width('92%')
          .layoutWeight(1)
          .padding({ top: 8 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      // 添加行程对话框
      if (this.showAddDialog) {
        this.buildAddDialog()
      }
    }
  }

  @Builder
  buildTripItem(item: TripItem, index: number) {
    Column() {
      Row() {
        // 天数标识
        Text(`第${index + 1}天`)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor('#1E90FF')
          .borderRadius(4)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })

        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 8 })
          .layoutWeight(1)

        if (item.duration > 0) {
          Text(`${item.duration}天`)
            .fontSize(11)
            .fontColor('#999999')
        }
      }
      .width('100%')

      if (item.city) {
        Text(item.city)
          .fontSize(12)
          .fontColor('#1E90FF')
          .margin({ top: 6 })
          .width('100%')
      }

      if (item.content) {
        Text(item.content)
          .fontSize(12)
          .fontColor('#666666')
          .maxLines(this.expandedTripIds.includes(item.id) ? 999 : 2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
          .width('100%')
          .onClick(() => {
            if (this.expandedTripIds.includes(item.id)) {
              this.expandedTripIds = this.expandedTripIds.filter(id => id !== item.id)
            } else {
              this.expandedTripIds.push(item.id)
              this.expandedTripIds = [...this.expandedTripIds]
            }
          })

        if (item.content.length > 30) {
          Text(this.expandedTripIds.includes(item.id) ? '收起' : '展开全文')
            .fontSize(12)
            .fontColor('#1E90FF')
            .margin({ top: 4 })
            .width('100%')
            .onClick(() => {
              if (this.expandedTripIds.includes(item.id)) {
                this.expandedTripIds = this.expandedTripIds.filter(id => id !== item.id)
              } else {
                this.expandedTripIds.push(item.id)
                this.expandedTripIds = [...this.expandedTripIds]
              }
            })
        }
      }

      Row() {
        // 上移按钮
        Button('↑ 上移')
          .fontSize(11)
          .height(26)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .borderRadius(13)
          .onClick(async () => {
            if (index > 0) {
              await TripService.getInstance().swapOrder(item.id, this.trips[index - 1].id)
              this.loadTrips()
            }
          })

        // 下移按钮
        Button('↓ 下移')
          .fontSize(11)
          .height(26)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .borderRadius(13)
          .margin({ left: 8 })
          .onClick(async () => {
            if (index < this.trips.length - 1) {
              await TripService.getInstance().swapOrder(item.id, this.trips[index + 1].id)
              this.loadTrips()
            }
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 2, color: '#10000000', offsetY: 1 })
  }

  @Builder
  buildDeleteButton(id: number) {
    Button() {
      Text('🗑')
        .fontSize(18)
        .fontColor('#FFFFFF')
    }
    .width(70)
    .height('100%')
    .backgroundColor('#FF4444')
    .onClick(async () => {
      await TripService.getInstance().deleteTrip(id)
      this.loadTrips()
      promptAction.showToast({ message: '已删除', duration: 1500 })
    })
  }

  @Builder
  buildAddDialog() {
    Column() {
      Column() {
        Text('添加行程')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding(16)
          .textAlign(TextAlign.Center)

        // 行程标题
        TextInput({ placeholder: '行程标题', text: this.newTripTitle })
          .width('90%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.newTripTitle = value })

        // 城市
        TextInput({ placeholder: '目的地城市', text: this.newTripCity })
          .width('90%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.newTripCity = value })

        // 天数选择
        Row() {
          Text('行程天数')
            .fontSize(14)
            .fontColor('#666666')
          Blank()
          Button('-')
            .fontSize(16)
            .width(30)
            .height(30)
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(15)
            .onClick(() => { if (this.newTripDays > 1) this.newTripDays-- })
          Text(`${this.newTripDays}`)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ left: 12, right: 12 })
          Button('+')
            .fontSize(16)
            .width(30)
            .height(30)
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(15)
            .onClick(() => { if (this.newTripDays < 15) this.newTripDays++ })
        }
        .width('90%')
        .margin({ bottom: 16 })

        Row() {
          Button('取消')
            .fontSize(14)
            .height(40)
            .layoutWeight(1)
            .backgroundColor('#F5F5F5')
            .fontColor('#666666')
            .borderRadius(8)
            .margin({ right: 8 })
            .onClick(() => {
              this.showAddDialog = false
              this.newTripTitle = ''
              this.newTripCity = ''
              this.newTripDays = 1
            })

          Button('确定')
            .fontSize(14)
            .height(40)
            .layoutWeight(1)
            .backgroundColor('#1E90FF')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .onClick(() => { this.addTrip() })
        }
        .width('90%')
        .margin({ bottom: 16 })
      }
      .width('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showAddDialog = false })
  }

  async addTrip(): Promise<void> {
    if (this.newTripTitle.trim().length === 0) {
      promptAction.showToast({ message: '请输入行程标题', duration: 1500 })
      return
    }
    try {
      await TripService.getInstance().createTrip(
        this.newTripTitle,
        this.newTripCity,
        this.newTripDays,
        ''
      )
      this.showAddDialog = false
      this.newTripTitle = ''
      this.newTripCity = ''
      this.newTripDays = 1
      this.loadTrips()
      promptAction.showToast({ message: '行程已添加', duration: 1500 })
    } catch (err) {
      promptAction.showToast({ message: '添加失败', duration: 1500 })
    }
  }
}