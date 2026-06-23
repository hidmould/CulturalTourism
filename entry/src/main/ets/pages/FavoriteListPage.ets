import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { FavoriteService } from '../service/FavoriteService'
import { FavoriteModel } from '../model/FavoriteModel'

/**
 * 收藏列表页面
 * 展示用户收藏的攻略内容
 */
@Entry
@Component
struct FavoriteListPage {
  @State favorites: FavoriteModel[] = []
  @State isLoading: boolean = true
  private favoriteService: FavoriteService = FavoriteService.getInstance()

  async aboutToAppear(): Promise<void> {
    await this.loadFavorites()
  }

  async loadFavorites(): Promise<void> {
    this.isLoading = true
    try {
      this.favorites = await this.favoriteService.getFavorites()
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

        Text('我的收藏')
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
      } else if (this.favorites.length === 0) {
        Column() {
          Text('⭐')
            .fontSize(48)
            .margin({ bottom: 12 })

          Text('暂无收藏')
            .fontSize(16)
            .fontColor('#999')

          Text('在对话中点击收藏按钮保存精彩内容')
            .fontSize(13)
            .fontColor('#CCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.favorites, (fav: FavoriteModel) => {
            ListItem() {
              this.FavoriteItem(fav)
            }
            .swipeAction({ end: this.DeleteButton(fav.id) })
          })
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#F0F0F0' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF')
  }

  @Builder
  FavoriteItem(fav: FavoriteModel) {
    Column() {
      Row() {
        Text(this.getTypeIcon(fav.favoriteType))
          .fontSize(20)
          .margin({ right: 10 })

        Text(fav.content)
          .fontSize(14)
          .fontColor('#333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')

      Text(this.formatTime(fav.createTime))
        .fontSize(11)
        .fontColor('#CCC')
        .margin({ top: 6 })
    }
    .width('100%')
    .padding(14)
  }

  @Builder
  DeleteButton(favId: number) {
    Button() {
      Text('取消收藏')
        .fontSize(14)
        .fontColor('#FFF')
    }
    .backgroundColor('#FF9500')
    .width(80)
    .height('100%')
    .onClick(() => {
      this.removeFavorite(favId)
    })
  }

  getTypeIcon(type: string): string {
    switch (type) {
      case 'spot': return '🏯'
      case 'route': return '🗺️'
      case 'food': return '🍜'
      default: return '💬'
    }
  }

  async removeFavorite(favId: number): Promise<void> {
    await this.favoriteService.removeFavorite(favId)
    promptAction.showToast({ message: '已取消收藏' })
    this.loadFavorites()
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const y = date.getFullYear()
    const m = (date.getMonth() + 1).toString().padStart(2, '0')
    const d = date.getDate().toString().padStart(2, '0')
    const h = date.getHours().toString().padStart(2, '0')
    const min = date.getMinutes().toString().padStart(2, '0')
    return `${y}-${m}-${d} ${h}:${min}`
  }
}