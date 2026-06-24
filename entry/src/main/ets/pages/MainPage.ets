/**
 * 主页 - Tab 导航：对话列表 / 发现 / 我的
 */
import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { ChatService } from '../service/ChatService'
import { ScenicService } from '../service/ScenicService'
import { UserService } from '../service/UserService'
import { Conversation, ScenicSpot, UserInfo } from '../model/Models'
import { ModelType } from '../common/Constants'

@Entry
@Component
struct MainPage {
  @State currentTab: number = 0
  @State conversations: Conversation[] = []
  @State searchKeyword: string = ''
  @State isLoading: boolean = false

  private tabsController: TabsController = new TabsController()

  aboutToAppear(): void {
    this.loadConversations()
  }

  onPageShow(): void {
    this.loadConversations()
  }

  async loadConversations(): Promise<void> {
    this.isLoading = true
    try {
      this.conversations = await ChatService.getInstance().getConversations()
    } catch (err) {
      console.error('加载对话列表失败')
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      // Tab 1: 对话列表
      TabContent() {
        this.buildChatListTab()
      }
      .tabBar(this.buildTabBar('对话', 0))

      // Tab 2: 发现
      TabContent() {
        DiscoverContent()
      }
      .tabBar(this.buildTabBar('发现', 1))

      // Tab 3: 我的
      TabContent() {
        ProfileContent()
      }
      .tabBar(this.buildTabBar('我的', 2))
    }
    .barHeight(56)
    .onChange((index: number) => {
      this.currentTab = index
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTabBar(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontColor(this.currentTab === index ? '#1E90FF' : '#999999')
        .margin({ top: 6 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildChatListTab() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('智慧文旅')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E90FF')
        Blank()
        Text('+')
          .fontSize(24)
          .fontColor('#1E90FF')
          .fontWeight(FontWeight.Bold)
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.createNewChat() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 搜索框
      Row() {
        Text('🔍')
          .fontSize(14)
          .margin({ left: 12 })
        TextInput({ placeholder: '搜索对话', text: this.searchKeyword })
          .layoutWeight(1)
          .height(36)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.searchKeyword = value
            this.searchConversations()
          })
      }
      .width('92%')
      .height(36)
      .backgroundColor('#F5F5F5')
      .borderRadius(18)
      .margin({ top: 8, bottom: 8 })

      // 对话列表
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 100 })
      } else if (this.conversations.length === 0) {
        Column() {
          Text('📝')
            .fontSize(40)
            .margin({ top: 80 })
          Text('暂无对话记录')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
          Text('点击右上角 + 开始新对话')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 4 })
        }
        .width('100%')
      } else {
        List() {
          ForEach(this.conversations, (item: Conversation) => {
            ListItem() {
              this.buildConversationItem(item)
            }
            .swipeAction({ end: this.buildDeleteButton(item.id) })
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildConversationItem(item: Conversation) {
    Row() {
      Column() {
        Text(this.getDisplayTitle(item))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.summary || '点击继续对话')
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text(this.formatTime(item.lastMessageTime))
          .fontSize(11)
          .fontColor('#BBBBBB')
        if (item.messageCount > 0) {
          Text(`${item.messageCount}`)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#1E90FF')
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.End)
      .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ChatPage', params: { conversationId: item.id } })
    })
  }

  @Builder
  buildDeleteButton(convId: number) {
    Button() {
      Text('🗑')
        .fontSize(18)
        .fontColor('#FFFFFF')
    }
    .width(70)
    .height('100%')
    .backgroundColor('#FF4444')
    .onClick(async () => {
      await ChatService.getInstance().deleteConversation(convId)
      this.loadConversations()
      promptAction.showToast({ message: '已删除', duration: 1500 })
    })
  }

  async createNewChat(): Promise<void> {
    try {
      let convId = await ChatService.getInstance().createConversation('新对话', ModelType.GENERAL)
      router.pushUrl({ url: 'pages/ChatPage', params: { conversationId: convId } })
    } catch (err) {
      promptAction.showToast({ message: '创建对话失败', duration: 1500 })
    }
  }

  async searchConversations(): Promise<void> {
    if (this.searchKeyword.length === 0) {
      this.loadConversations()
      return
    }
    try {
      this.conversations = await ChatService.getInstance().searchConversations(this.searchKeyword)
    } catch (err) {
      console.error('搜索失败')
    }
  }

  getDisplayTitle(item: Conversation): string {
    if (item.title && item.title !== '新对话') {
      return item.title
    }
    if (item.summary && item.summary.trim().length > 0) {
      let summary = item.summary.trim()
      return summary.length > 12 ? summary.substring(0, 12) + '...' : summary
    }
    return '新对话'
  }

  formatTime(timestamp: number): string {
    if (timestamp === 0) return ''
    let date = new Date(timestamp)
    let now = new Date()
    let diff = now.getTime() - date.getTime()
    let dayDiff = Math.floor(diff / (1000 * 60 * 60 * 24))

    if (dayDiff === 0) {
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
    } else if (dayDiff === 1) {
      return '昨天'
    } else if (dayDiff < 7) {
      return `${dayDiff}天前`
    } else {
      return `${date.getMonth() + 1}/${date.getDate()}`
    }
  }
}

// ==================== 发现页内容 ====================

@Component
struct DiscoverContent {
  @State categories: string[] = ScenicService.getInstance().getCategories()
  @State selectedCategory: string = '全部'
  @State spots: ScenicSpot[] = []
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadSpots()
  }

  async loadSpots(): Promise<void> {
    this.isLoading = true
    try {
      this.spots = await ScenicService.getInstance().getAllSpots()
    } catch (err) {
      console.error('加载景点失败')
    } finally {
      this.isLoading = false
    }
  }

  async filterByCategory(category: string): Promise<void> {
    this.selectedCategory = category
    this.isLoading = true
    try {
      if (category === '全部') {
        this.spots = await ScenicService.getInstance().getAllSpots()
      } else {
        this.spots = await ScenicService.getInstance().getSpotsByCategory(category)
      }
    } catch (err) {
      console.error('筛选失败')
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 天气预告快捷入口
      Column() {
        Row() {
          Text('🌤️')
            .fontSize(28)
            .margin({ left: 4 })
          Column() {
            Text('天气预告')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text('实时天气 · 未来预报 · 出行建议')
              .fontSize(11)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })
          .layoutWeight(1)

          Text('→')
            .fontSize(18)
            .fontColor('#CCCCCC')
            .margin({ right: 4 })
        }
        .width('100%')
        .padding(14)
      }
      .width('92%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 8 })
      .shadow({ radius: 4, color: '#15000000', offsetY: 2 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/WeatherPage' })
      })

      // 标题
      Text('景点发现')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1E90FF')
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

      // 分类筛选
      Scroll() {
        Row() {
          Button('全部')
            .fontSize(12)
            .height(30)
            .backgroundColor(this.selectedCategory === '全部' ? '#1E90FF' : '#F0F0F0')
            .fontColor(this.selectedCategory === '全部' ? '#FFFFFF' : '#666666')
            .borderRadius(15)
            .margin({ right: 8 })
            .onClick(() => { this.filterByCategory('全部') })

          ForEach(this.categories, (cat: string) => {
            Button(cat)
              .fontSize(12)
              .height(30)
              .backgroundColor(this.selectedCategory === cat ? '#1E90FF' : '#F0F0F0')
              .fontColor(this.selectedCategory === cat ? '#FFFFFF' : '#666666')
              .borderRadius(15)
              .margin({ right: 8 })
              .onClick(() => { this.filterByCategory(cat) })
          })
        }
        .padding({ left: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(44)
      .margin({ top: 4 })

      // 景点列表
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 80 })
      } else {
        List() {
          ForEach(this.spots, (spot: ScenicSpot) => {
            ListItem() {
              this.buildSpotCard(spot)
            }
            .margin({ bottom: 12 })
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
  }

  @Builder
  buildSpotCard(spot: ScenicSpot) {
    Column() {
      // 景点图片占位
      Row() {
        Text(spot.name.substring(0, 1))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(120)
      .backgroundColor(this.getCategoryColor(spot.category))
      .justifyContent(FlexAlign.Center)
      .borderRadius({ topLeft: 12, topRight: 12 })

      Column() {
        Row() {
          Text(spot.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Blank()
          Text(`${spot.rating}分`)
            .fontSize(12)
            .fontColor('#FF8800')
        }
        .width('100%')

        Text(spot.description)
          .fontSize(12)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
          .width('100%')

        Row() {
          Text(spot.category)
            .fontSize(10)
            .fontColor('#1E90FF')
            .backgroundColor('#E8F4FD')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          Text(spot.city)
            .fontSize(10)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 12, bottomRight: 12 })
    }
    .width('100%')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
  }

  getCategoryColor(category: string): string {
    switch (category) {
      case '自然风光': return '#4CAF50'
      case '历史人文': return '#FF9800'
      case '网红打卡': return '#E91E63'
      case '美食街区': return '#F44336'
      default: return '#607D8B'
    }
  }
}

// ==================== 我的页面内容 ====================

@Component
struct ProfileContent {
  @State userInfo: UserInfo = new UserInfo()
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadUserInfo()
  }

  async loadUserInfo(): Promise<void> {
    this.isLoading = true
    try {
      this.userInfo = await UserService.getInstance().getUserInfo()
    } catch (err) {
      console.error('加载用户信息失败')
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 用户信息卡片
      Column() {
        Row() {
          // 头像
          Text(this.userInfo.nickname ? this.userInfo.nickname.substring(0, 1) : '?')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .width(60)
            .height(60)
            .backgroundColor('#1E90FF')
            .borderRadius(30)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              router.pushUrl({ url: 'pages/ProfilePage' })
            })

          Column() {
            Text(this.userInfo.nickname || '未设置昵称')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text(this.userInfo.phone || '')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })

          Blank()

          Text('→')
          .fontSize(18)
          .fontColor('#999999')
        }
        .width('100%')
        .padding(16)

        // 偏好标签
        if (this.userInfo.travelPreference || this.userInfo.residentCity) {
          Row() {
            if (this.userInfo.travelPreference) {
              Text(`偏好: ${this.userInfo.travelPreference}`)
                .fontSize(11)
                .fontColor('#1E90FF')
                .backgroundColor('#E8F4FD')
                .borderRadius(4)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            }
            if (this.userInfo.residentCity) {
              Text(`常住: ${this.userInfo.residentCity}`)
                .fontSize(11)
                .fontColor('#1E90FF')
                .backgroundColor('#E8F4FD')
                .borderRadius(4)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .margin({ left: 8 })
            }
          }
          .width('100%')
          .padding({ left: 16, bottom: 12 })
        }
      }
      .width('92%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 12 })
      .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/ProfilePage' })
      })

      // 功能入口
      Column() {
        this.buildMenuItem('收藏', '已收藏的攻略和景点', () => {
          router.pushUrl({ url: 'pages/FavoritesPage' })
        })
        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 16 })
        this.buildMenuItem('行程清单', '管理您的旅行计划', () => {
          router.pushUrl({ url: 'pages/TripDetailPage' })
        })
        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 16 })
        this.buildMenuItem('天气预告', '实时天气与未来预报', () => {
          router.pushUrl({ url: 'pages/WeatherPage' })
        })
        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 16 })
        this.buildMenuItem('清除缓存', '释放存储空间', () => {
          this.clearCache()
        })
        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 16 })
        this.buildMenuItem('关于应用', '智慧文旅 v1.0.0', () => {
          promptAction.showToast({ message: '智慧文旅 v1.0.0\nAI驱动的智能旅行助手', duration: 2000 })
        })
      }
      .width('92%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 12 })
      .shadow({ radius: 4, color: '#10000000', offsetY: 2 })

      // 退出登录
      Button('退出登录')
        .width('92%')
        .height(44)
        .fontSize(14)
        .fontColor('#FF4444')
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .margin({ top: 30 })
        .onClick(async () => {
          await UserService.getInstance().logout()
          router.replaceUrl({ url: 'pages/LoginPage' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  @Builder
  buildMenuItem(title: string, desc: string, action: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
        Text(desc)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('→')
          .fontSize(16)
          .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(action)
  }

  clearCache(): void {
    promptAction.showToast({ message: '缓存已清除', duration: 1500 })
  }
}