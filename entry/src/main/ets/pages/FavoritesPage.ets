/**
 * 收藏列表页面
 */
import { router } from '@kit.ArkUI'
import { FavoriteService } from '../service/FavoriteService'
import { Favorite } from '../model/Models'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct FavoritesPage {
  @State favorites: Favorite[] = []
  @State isLoading: boolean = false
  @State selectedType: string = '全部'

  aboutToAppear(): void {
    this.loadFavorites()
  }

  async loadFavorites(): Promise<void> {
    this.isLoading = true
    try {
      this.favorites = await FavoriteService.getInstance().getAllFavorites()
    } catch (err) {
      console.error('加载收藏失败')
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => { router.back() })
        Text('我的收藏')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // 类型筛选
      Scroll() {
        Row() {
          Button('全部')
            .fontSize(12)
            .height(30)
            .backgroundColor(this.selectedType === '全部' ? '#1E90FF' : '#F0F0F0')
            .fontColor(this.selectedType === '全部' ? '#FFFFFF' : '#666666')
            .borderRadius(15)
            .margin({ right: 8 })
            .onClick(() => { this.selectedType = '全部' })

          ForEach(['spot_explanation', 'route_plan', 'food_recommend', 'hotel_recommend'], (type: string) => {
            Button(this.getTypeName(type))
              .fontSize(12)
              .height(30)
              .backgroundColor(this.selectedType === type ? '#1E90FF' : '#F0F0F0')
              .fontColor(this.selectedType === type ? '#FFFFFF' : '#666666')
              .borderRadius(15)
              .margin({ right: 8 })
              .onClick(() => { this.selectedType = type })
          })
        }
        .padding({ left: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(44)
      .margin({ top: 8, bottom: 8 })

      // 收藏列表
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 100 })
      } else if (this.favorites.length === 0) {
        Column() {
          Text('暂无收藏')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 100 })
        }
        .width('100%')
      } else {
        List() {
          ForEach(this.favorites.filter(f => this.selectedType === '全部' || f.type === this.selectedType), (item: Favorite) => {
            ListItem() {
              this.buildFavoriteItem(item)
            }
            .margin({ bottom: 8 })
            .swipeAction({ end: this.buildDeleteButton(item.id) })
          })
        }
        .width('92%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  @Builder
  buildFavoriteItem(item: Favorite) {
    Column() {
      Row() {
        Text(this.getTypeName(item.type))
          .fontSize(10)
          .fontColor('#1E90FF')
          .backgroundColor('#E8F4FD')
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        Blank()
        Text(this.formatTime(item.createTime))
          .fontSize(11)
          .fontColor('#BBBBBB')
      }
      .width('100%')

      Text(item.content)
        .fontSize(13)
        .fontColor('#333333')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width('100%')
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
      await FavoriteService.getInstance().deleteFavorite(id)
      this.loadFavorites()
      promptAction.showToast({ message: '已删除', duration: 1500 })
    })
  }

  getTypeName(type: string): string {
    switch (type) {
      case 'spot_explanation': return '景点讲解'
      case 'route_plan': return '路线规划'
      case 'food_recommend': return '美食推荐'
      case 'hotel_recommend': return '住宿推荐'
      default: return type
    }
  }

  formatTime(timestamp: number): string {
    if (timestamp === 0) return ''
    let date = new Date(timestamp)
    return `${date.getMonth() + 1}/${date.getDate()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
  }
}