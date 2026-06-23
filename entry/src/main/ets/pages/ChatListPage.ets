import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { ChatService } from '../service/ChatService'
import { AuthService } from '../service/AuthService'
import { ChatModel } from '../model/ChatModel'

/**
 * 对话列表页面
 * 显示所有历史对话，支持搜索、删除，新建对话入口
 */
@Entry
@Component
struct ChatListPage {
  @State chatList: ChatModel[] = []
  @State searchKeyword: string = ''
  @State isLoading: boolean = true
  private chatService: ChatService = ChatService.getInstance()
  private authService: AuthService = AuthService.getInstance()

  async aboutToAppear(): Promise<void> {
    await this.loadChats()
  }

  async loadChats(): Promise<void> {
    this.isLoading = true
    try {
      if (this.searchKeyword) {
        this.chatList = await this.chatService.searchChats(this.searchKeyword)
      } else {
        this.chatList = await this.chatService.getChatList()
      }
    } catch (_err) {
      // ignore
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('文旅对话')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Blank()

        Button() {
          Text('👤')
            .fontSize(20)
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ProfilePage' })
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索对话...', text: this.searchKeyword })
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .height(36)
          .padding({ left: 16 })
          .onChange((value: string) => {
            this.searchKeyword = value
            this.loadChats()
          })

        if (this.searchKeyword) {
          Text('取消')
            .fontSize(14)
            .fontColor('#007AFF')
            .margin({ left: 8 })
            .onClick(() => {
              this.searchKeyword = ''
              this.loadChats()
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 底部Tab切换
      Row() {
        this.TabButton('对话', 0, true)
        this.TabButton('发现', 1, false)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 对话列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .margin({ top: 60 })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.chatList.length === 0) {
        Column() {
          Text('💬')
            .fontSize(48)
            .margin({ bottom: 12 })

          Text('暂无对话')
            .fontSize(16)
            .fontColor('#999')

          Text('点击下方按钮开始新对话')
            .fontSize(13)
            .fontColor('#CCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.chatList, (chat: ChatModel) => {
            ListItem() {
              this.ChatListItem(chat)
            }
            .swipeAction({ end: this.DeleteButton(chat.id) })
          })
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#F0F0F0' })
      }

      // 新建对话按钮
      Button() {
        Row() {
          Text('+')
            .fontSize(20)
            .margin({ right: 6 })
          Text('新建对话')
            .fontSize(16)
        }
      }
      .width('90%')
      .height(48)
      .fontColor('#FFF')
      .backgroundColor('#007AFF')
      .borderRadius(24)
      .margin({ bottom: 16 })
      .onClick(() => { this.createNewChat() })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF')
  }

  @Builder
  TabButton(text: string, index: number, isActive: boolean) {
    Text(text)
      .fontSize(15)
      .fontColor(isActive ? '#007AFF' : '#999')
      .fontWeight(isActive ? FontWeight.Bold : FontWeight.Normal)
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .onClick(() => {
        if (index === 1) {
          router.pushUrl({ url: 'pages/SpotDiscoveryPage' })
        }
      })
  }

  @Builder
  ChatListItem(chat: ChatModel) {
    Row() {
      Column() {
        Text(chat.title || '新对话')
          .fontSize(16)
          .fontColor('#333')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(chat.summary || '暂无消息')
          .fontSize(13)
          .fontColor('#999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.formatTime(chat.lastMessageTime))
        .fontSize(12)
        .fontColor('#CCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/ChatDetailPage',
        params: { chatId: chat.id, chatTitle: chat.title }
      })
    })
  }

  @Builder
  DeleteButton(chatId: number) {
    Button() {
      Text('删除')
        .fontSize(14)
        .fontColor('#FFF')
    }
    .backgroundColor('#FF3B30')
    .width(70)
    .height('100%')
    .onClick(() => {
      this.deleteChat(chatId)
    })
  }

  async deleteChat(chatId: number): Promise<void> {
    await this.chatService.deleteChat(chatId)
    promptAction.showToast({ message: '已删除' })
    this.loadChats()
  }

  async createNewChat(): Promise<void> {
    const chatId = await this.chatService.createChat('新对话')
    router.pushUrl({
      url: 'pages/ChatDetailPage',
      params: { chatId: chatId, chatTitle: '新对话' }
    })
  }

  formatTime(timestamp: number): string {
    const now = Date.now()
    const diff = now - timestamp
    const minutes = Math.floor(diff / 60000)
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)

    if (minutes < 1) return '刚刚'
    if (minutes < 60) return `${minutes}分钟前`
    if (hours < 24) return `${hours}小时前`
    if (days < 7) return `${days}天前`
    const date = new Date(timestamp)
    return `${date.getMonth() + 1}/${date.getDate()}`
  }
}