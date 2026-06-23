import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { TripService } from '../service/TripService'
import { TripModel } from '../model/TripModel'

/**
 * 行程清单页面
 * 管理用户的行程列表
 */
@Entry
@Component
struct TripListPage {
  @State trips: TripModel[] = []
  @State isLoading: boolean = true
  @State showDialog: boolean = false
  @State newTripTitle: string = ''
  @State newTripDest: string = ''
  @State newTripDays: number = 1
  private tripService: TripService = TripService.getInstance()

  async aboutToAppear(): Promise<void> {
    await this.loadTrips()
  }

  async loadTrips(): Promise<void> {
    this.isLoading = true
    try {
      this.trips = await this.tripService.getTrips()
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Stack() {
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

          Text('行程清单')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Button() {
            Text('+')
              .fontSize(24)
              .fontColor('#007AFF')
          }
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.showDialog = true })
        }
        .width('100%')
        .height(52)
        .padding({ left: 8, right: 8 })

        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(30)
              .height(30)
              .margin({ top: 60 })
          }
          .width('100%')
          .layoutWeight(1)
        } else if (this.trips.length === 0) {
          Column() {
            Text('📋')
              .fontSize(48)
              .margin({ bottom: 12 })

            Text('暂无行程')
              .fontSize(16)
              .fontColor('#999')

            Text('点击右上角 + 创建新行程')
              .fontSize(13)
              .fontColor('#CCC')
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.trips, (trip: TripModel) => {
              ListItem() {
                this.TripCard(trip)
              }
              .swipeAction({ end: this.TripDeleteButton(trip.id) })
            })
          }
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 8 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFF')

      // 新建行程对话框
      if (this.showDialog) {
        Column() {
          Column() {
            Text('新建行程')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })

            TextInput({ placeholder: '行程标题', text: this.newTripTitle })
              .width('100%')
              .height(40)
              .fontSize(14)
              .border({ width: 1, color: '#E0E0E0', radius: 8 })
              .padding({ left: 12 })
              .margin({ bottom: 12 })
              .onChange((value: string) => { this.newTripTitle = value })

            TextInput({ placeholder: '目的地城市', text: this.newTripDest })
              .width('100%')
              .height(40)
              .fontSize(14)
              .border({ width: 1, color: '#E0E0E0', radius: 8 })
              .padding({ left: 12 })
              .margin({ bottom: 12 })
              .onChange((value: string) => { this.newTripDest = value })

            // 天数选择
            Row() {
              Text('行程天数')
                .fontSize(14)
                .fontColor('#333')

              Blank()

              Button('-')
                .width(32)
                .height(32)
                .fontSize(16)
                .borderRadius(16)
                .backgroundColor('#F0F0F0')
                .onClick(() => {
                  if (this.newTripDays > 1) {
                    this.newTripDays--
                  }
                })

              Text(this.newTripDays.toString())
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ left: 12, right: 12 })

              Button('+')
                .width(32)
                .height(32)
                .fontSize(16)
                .borderRadius(16)
                .backgroundColor('#F0F0F0')
                .onClick(() => {
                  if (this.newTripDays < 14) {
                    this.newTripDays++
                  }
                })
            }
            .width('100%')
            .margin({ bottom: 16 })

            Row() {
              Button('取消')
                .fontSize(14)
                .fontColor('#666')
                .backgroundColor('#F0F0F0')
                .layoutWeight(1)
                .height(40)
                .borderRadius(8)
                .onClick(() => { this.showDialog = false })

              Button('创建')
                .fontSize(14)
                .fontColor('#FFF')
                .backgroundColor('#007AFF')
                .layoutWeight(1)
                .height(40)
                .borderRadius(8)
                .margin({ left: 12 })
                .onClick(() => { this.createTrip() })
            }
            .width('100%')
          }
          .width('85%')
          .padding(20)
          .borderRadius(16)
          .backgroundColor('#FFF')
          .shadow({ radius: 20, color: '#00000020' })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000050')
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.showDialog = false })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TripCard(trip: TripModel) {
    Column() {
      Row() {
        Column() {
          Text(trip.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          Text(`${trip.destination} · ${trip.days}天`)
            .fontSize(13)
            .fontColor('#999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (trip.isGenerated === 1) {
          Text('AI生成')
            .fontSize(10)
            .fontColor('#007AFF')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
            .backgroundColor('#E8F0FE')
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor('#FAFAFA')
    .margin({ bottom: 10 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/TripDetailPage',
        params: { tripId: trip.id }
      })
    })
  }

  @Builder
  TripDeleteButton(tripId: number) {
    Button() {
      Text('删除')
        .fontSize(14)
        .fontColor('#FFF')
    }
    .backgroundColor('#FF3B30')
    .width(70)
    .height('100%')
    .onClick(() => {
      this.deleteTrip(tripId)
    })
  }

  async createTrip(): Promise<void> {
    if (!this.newTripTitle.trim() || !this.newTripDest.trim()) {
      promptAction.showToast({ message: '请填写行程标题和目的地' })
      return
    }

    const trip = new TripModel()
    trip.title = this.newTripTitle.trim()
    trip.destination = this.newTripDest.trim()
    trip.days = this.newTripDays

    await this.tripService.saveTrip(trip)
    this.showDialog = false
    this.newTripTitle = ''
    this.newTripDest = ''
    this.newTripDays = 1
    promptAction.showToast({ message: '行程已创建' })
    this.loadTrips()
  }

  async deleteTrip(tripId: number): Promise<void> {
    await this.tripService.deleteTrip(tripId)
    promptAction.showToast({ message: '已删除' })
    this.loadTrips()
  }
}