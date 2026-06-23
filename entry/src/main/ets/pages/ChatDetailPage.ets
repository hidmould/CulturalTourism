import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { ChatService } from '../service/ChatService'
import { FavoriteService } from '../service/FavoriteService'
import { MessageModel, ModelConfig, DEFAULT_MODELS } from '../model/ChatModel'
import { MessageBubble } from '../common/MessageBubble'
import { ModelSelector } from '../common/ModelSelector'

/**
 * 聊天对话页面
 * 功能：流式渲染、多模型切换、收藏、加入行程
 */
@Entry
@Component
struct ChatDetailPage {
  @State messages: MessageModel[] = []
  @State inputText: string = ''
  @State streamingContent: string = ''
  @State isStreaming: boolean = false
  @State selectedModelType: string = 'general'
  @State showModelPanel: boolean = false
  private chatId: number = 0
  private chatTitle: string = '新对话'
  private chatService: ChatService = ChatService.getInstance()
  private favoriteService: FavoriteService = FavoriteService.getInstance()
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.chatId = params['chatId'] as number
      this.chatTitle = params['chatTitle'] as string
    }
    this.selectedModelType = this.chatService.getCurrentModel().type
    this.loadMessages()
  }

  async loadMessages(): Promise<void> {
    this.messages = await this.chatService.getMessages(this.chatId)
    // 更新收藏状态
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].role === 'assistant') {
        const favResult = await this.favoriteService.isFavorite(this.messages[i].id)
        this.messages[i].isFavorite = favResult ? 1 : 0
      }
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button() {
          Text('‹')
            .fontSize(24)
            .fontColor('#007AFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .onClick(() => { router.back() })

        Text(this.chatTitle)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button() {
          Text('...')
            .fontSize(20)
            .fontColor('#007AFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.showModelPanel = !this.showModelPanel })
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 8 })
      .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // 模型选择面板
      if (this.showModelPanel) {
        Column() {
          Text('选择模型')
            .fontSize(13)
            .fontColor('#999')
            .margin({ bottom: 8 })

          ModelSelector({
            selectedModelType: this.selectedModelType,
            onModelChange: (type: string) => {
              this.selectedModelType = type
              this.chatService.setModel(type)
              this.showModelPanel = false
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#FAFAFA')
        .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
      }

      // 快捷问题区域
      if (this.messages.length === 0 && !this.isStreaming) {
        Column() {
          Text('试试问我这些问题：')
            .fontSize(14)
            .fontColor('#999')
            .margin({ bottom: 12 })

          Row() {
            this.QuickQuestion('推荐景点')
            this.QuickQuestion('规划路线')
          }
          .margin({ bottom: 8 })

          Row() {
            this.QuickQuestion('特色美食')
            this.QuickQuestion('天气穿搭')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 20 })
      }

      // 消息列表
      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: MessageModel) => {
          ListItem() {
            MessageBubble({
              role: msg.role,
              content: msg.content,
              isStreaming: false,
              isFavorite: msg.isFavorite === 1,
              onFavorite: () => { this.toggleFavorite(msg) },
              onAddToTrip: () => { this.addToTrip(msg) }
            })
          }
        })

        // 流式输出中的消息
        if (this.isStreaming) {
          ListItem() {
            MessageBubble({
              role: 'assistant',
              content: this.streamingContent,
              isStreaming: true,
              isFavorite: false
            })
          }
        }
      }
      .layoutWeight(1)
      .onScrollIndex((_: number, last: number) => {
        if (last >= this.messages.length - 1) {
          this.scroller.scrollEdge(Edge.Bottom)
        }
      })

      // 底部输入区域
      Row() {
        TextInput({ placeholder: '输入您的问题...', text: this.inputText })
          .fontSize(15)
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .enabled(!this.isStreaming)
          .onChange((value: string) => { this.inputText = value })
          .onSubmit(() => { this.sendMessage() })

        Button() {
          Text(this.isStreaming ? '■' : '↑')
            .fontSize(18)
            .fontColor('#FFF')
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.inputText.trim() ? '#007AFF' : '#CCC')
        .margin({ left: 8 })
        .enabled(this.inputText.trim().length > 0 && !this.isStreaming)
        .onClick(() => { this.sendMessage() })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .border({ width: { top: 0.5 }, color: '#E0E0E0' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF')
  }

  @Builder
  QuickQuestion(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor('#007AFF')
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .borderRadius(16)
      .border({ width: 1, color: '#007AFF' })
      .margin({ right: 8 })
      .onClick(() => {
        this.inputText = text
        this.sendMessage()
      })
  }

  /**
   * 发送消息
   */
  async sendMessage(): Promise<void> {
    const text = this.inputText.trim()
    if (!text || this.isStreaming) {
      return
    }

    this.inputText = ''
    this.isStreaming = true
    this.streamingContent = ''

    // 滚动到底部
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    }, 100)

    try {
      await this.chatService.sendMessageStream(
        this.chatId,
        text,
        (delta: string) => {
          // 流式追加文本
          this.streamingContent += delta
          this.scroller.scrollEdge(Edge.Bottom)
        },
        (_fullContent: string) => {
          // 流式完成
          this.isStreaming = false
          this.streamingContent = ''
          this.loadMessages()
          this.scroller.scrollEdge(Edge.Bottom)
        },
        (error: string) => {
          // 错误处理
          this.isStreaming = false
          this.streamingContent = ''
          promptAction.showToast({ message: error })
          this.loadMessages()
        }
      )
    } catch (err) {
      this.isStreaming = false
      this.streamingContent = ''
      promptAction.showToast({ message: '发送失败' })
    }
  }

  /**
   * 收藏/取消收藏消息
   */
  async toggleFavorite(msg: MessageModel): Promise<void> {
    if (msg.isFavorite === 1) {
      // 取消收藏 - 需要找到收藏记录ID
      promptAction.showToast({ message: '已取消收藏' })
    } else {
      await this.favoriteService.addFavorite(
        msg.id,
        this.chatId,
        msg.content.substring(0, 100),
        msg.messageType
      )
      msg.isFavorite = 1
      promptAction.showToast({ message: '已收藏' })
    }
  }

  /**
   * 加入行程
   */
  addToTrip(msg: MessageModel): void {
    router.pushUrl({
      url: 'pages/TripListPage',
      params: { messageContent: msg.content, fromChat: true }
    })
  }
}