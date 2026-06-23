import { router } from '@kit.ArkUI'
import { TripService } from '../service/TripService'
import { TripModel, ScheduleItem, ScheduleDetail } from '../model/TripModel'

/**
 * 行程详情页面
 * 按天展示行程安排
 */
@Entry
@Component
struct TripDetailPage {
  @State trip: TripModel | null = null
  @State schedule: ScheduleItem[] = []
  @State isLoading: boolean = true
  private tripId: number = 0
  private tripService: TripService = TripService.getInstance()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.tripId = params['tripId'] as number
    }
    this.loadTripDetail()
  }

  async loadTripDetail(): Promise<void> {
    this.isLoading = true
    try {
      this.trip = await this.tripService.getTripById(this.tripId)
      if (this.trip) {
        this.schedule = this.tripService.parseSchedule(this.trip)
      }
    } finally {
      this.isLoading = false
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

        Text(this.trip?.title || '行程详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
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
      } else if (this.trip) {
        // 行程概要
        Column() {
          Text(`${this.trip.destination} · ${this.trip.days}天行程`)
            .fontSize(14)
            .fontColor('#666')
            .margin({ top: 4 })

          if (this.trip.startDate) {
            Text(`出发日期：${this.trip.startDate}`)
              .fontSize(13)
              .fontColor('#999')
              .margin({ top: 4 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 12 })

        // 日程列表
        if (this.schedule.length > 0) {
          List() {
            ForEach(this.schedule, (item: ScheduleItem) => {
              ListItem() {
                this.DaySchedule(item)
              }
            })
          }
          .layoutWeight(1)
        } else {
          Column() {
            Text('📝')
              .fontSize(48)
              .margin({ bottom: 12 })

            Text('暂无日程安排')
              .fontSize(16)
              .fontColor('#999')

            Text('去对话中让AI帮你生成行程吧')
              .fontSize(13)
              .fontColor('#CCC')
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF')
  }

  @Builder
  DaySchedule(scheduleItem: ScheduleItem) {
    Column() {
      // 日期标题
      Row() {
        Text(`Day ${scheduleItem.day}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(8)
          .backgroundColor('#E8F0FE')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 日程详情
      ForEach(scheduleItem.items, (detail: ScheduleDetail, index: number) => {
        Row() {
          // 时间线
          Column() {
            Text(detail.time)
              .fontSize(12)
              .fontColor('#999')
              .width(48)

            if (index < scheduleItem.items.length - 1) {
              Divider()
                .vertical(true)
                .height(40)
                .width(1)
                .color('#E0E0E0')
                .margin({ left: 23 })
            }
          }
          .alignItems(HorizontalAlign.Center)

          // 活动内容
          Column() {
            Text(detail.activity)
              .fontSize(14)
              .fontColor('#333')
              .fontWeight(FontWeight.Medium)

            Row() {
              Text(`📍 ${detail.location}`)
                .fontSize(12)
                .fontColor('#999')
                .margin({ right: 4 })

              if (detail.note) {
                Text(`💡 ${detail.note}`)
                  .fontSize(12)
                  .fontColor('#FF9500')
              }
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 8 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      })
    }
    .width('100%')
    .padding({ bottom: 8 })
    .margin({ bottom: 8 })
  }
}