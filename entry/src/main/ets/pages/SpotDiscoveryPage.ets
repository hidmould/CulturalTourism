import { router } from '@kit.ArkUI'
import { SpotService } from '../service/SpotService'
import { ScenicSpotModel, SPOT_CATEGORIES } from '../model/ScenicSpotModel'

/**
 * 景点分类浏览页面
 * 按自然风光/历史人文/网红打卡分类展示景点卡片
 */
@Entry
@Component
struct SpotDiscoveryPage {
  @State spots: ScenicSpotModel[] = []
  @State selectedCategory: string = ''
  @State searchKeyword: string = ''
  @State isLoading: boolean = true
  @State categories: string[] = ['全部', ...SPOT_CATEGORIES]
  private spotService: SpotService = SpotService.getInstance()

  async aboutToAppear(): Promise<void> {
    await this.loadSpots()
  }

  async loadSpots(): Promise<void> {
    this.isLoading = true
    try {
      if (this.searchKeyword) {
        this.spots = await this.spotService.searchSpots(this.searchKeyword)
      } else {
        this.spots = await this.spotService.getSpotsByCategory(this.selectedCategory)
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

        Text('发现景点')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 8 })

      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索景点...', text: this.searchKeyword })
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .height(36)
          .padding({ left: 16 })
          .onChange((value: string) => {
            this.searchKeyword = value
            this.loadSpots()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 分类标签
      Scroll() {
        Row() {
          ForEach(this.categories, (cat: string) => {
            Text(cat)
              .fontSize(13)
              .fontColor(cat === (this.selectedCategory || '全部') ? '#FFF' : '#666')
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(cat === (this.selectedCategory || '全部') ? '#007AFF' : '#F0F0F0')
              .margin({ right: 8 })
              .onClick(() => {
                this.selectedCategory = cat === '全部' ? '' : cat
                this.loadSpots()
              })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(44)

      // 景点列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .margin({ top: 60 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.spots, (spot: ScenicSpotModel) => {
            ListItem() {
              this.SpotCard(spot)
            }
          })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF')
  }

  @Builder
  SpotCard(spot: ScenicSpotModel) {
    Column() {
      Row() {
        Column() {
          Text(spot.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          Row() {
            Text('⭐')
              .fontSize(12)
            Text(spot.rating.toString())
              .fontSize(13)
              .fontColor('#FF9500')
              .margin({ right: 8 })

            Text(spot.city)
              .fontSize(12)
              .fontColor('#999')
              .margin({ right: 8 })

            Text(spot.category)
              .fontSize(11)
              .fontColor('#007AFF')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
              .backgroundColor('#E8F0FE')
          }
          .margin({ top: 6 })

          Text(spot.description)
            .fontSize(13)
            .fontColor('#666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })

          // 标签
          if (spot.tags) {
            Row() {
              ForEach(spot.tags.split(','), (tag: string) => {
                Text(`#${tag}`)
                  .fontSize(11)
                  .fontColor('#999')
                  .margin({ right: 4 })
              })
            }
            .margin({ top: 6 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor('#FAFAFA')
    .margin({ bottom: 12 })
  }
}