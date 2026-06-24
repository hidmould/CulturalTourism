/**
 * 聊天对话窗口 - 流式对话、多模型切换、收藏、加入行程
 */
import { router } from '@kit.ArkUI'
import { ChatService } from '../service/ChatService'
import { FavoriteService } from '../service/FavoriteService'
import { TripService } from '../service/TripService'
import { WeatherService } from '../service/WeatherService'
import { ChatMessage } from '../model/Models'
import { ModelType, ModelConfig, MODEL_CONFIGS, MessageRole } from '../common/Constants'
import { promptAction } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'

interface MessageItem {
  id: number
  role: string
  content: string
  isStreaming: boolean
  createTime: number
}

@Entry
@Component
struct ChatPage {
  @State messages: MessageItem[] = []
  @State inputText: string = ''
  @State isLoading: boolean = false
  @State streamingContent: string = ''
  @State isStreaming: boolean = false
  @State currentModelType: ModelType = ModelType.GENERAL
  @State showModelPicker: boolean = false
  @State showActionSheet: boolean = false
  @State selectedMessage: MessageItem | null = null
  private conversationId: number = 0
  private scroller: Scroller = new Scroller()
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  aboutToAppear(): void {
    let params = router.getParams() as Record<string, Object>
    if (params && params['conversationId']) {
      this.conversationId = params['conversationId'] as number
    }
    this.currentModelType = ChatService.getInstance().getCurrentModel()
    this.loadMessages()
  }

  async loadMessages(): Promise<void> {
    let msgs = await ChatService.getInstance().getMessages(this.conversationId)
    let items: MessageItem[] = []
    for (let i = 0; i < msgs.length; i++) {
      let m = msgs[i]
      let item: MessageItem = {
        id: m.id,
        role: m.role,
        content: m.content,
        isStreaming: false,
        createTime: m.createTime
      }
      items.push(item)
    }
    this.messages = items
    this.scrollToBottom()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部标题栏
        this.buildTopBar()

        // 消息列表
        Scroll(this.scroller) {
          Column() {
            // 欢迎提示
            if (this.messages.length === 0) {
              this.buildWelcomeTips()
            }

            ForEach(this.messages, (item: MessageItem) => {
              this.buildMessageBubble(item)
            })

            // 流式输出中的消息
            if (this.isStreaming) {
              this.buildStreamingBubble()
            }

            // 加载指示器
            if (this.isLoading && !this.isStreaming) {
              Row() {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color('#999999')
                Text('AI 正在思考...')
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ left: 8 })
              }
              .width('100%')
              .padding(12)
              .justifyContent(FlexAlign.Start)
            }
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 8, bottom: 60 })
          .alignItems(HorizontalAlign.Start)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F5F5F5')

        // 底部输入框
        this.buildInputBar()
      }
      .width('100%')
      .height('100%')

      // 模型选择器弹窗
      if (this.showModelPicker) {
        this.buildModelPicker()
      }

      // 操作菜单弹窗
      if (this.showActionSheet && this.selectedMessage) {
        this.buildActionSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildTopBar() {
    Row() {
      Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => { router.back() })

      Text('智慧文旅助手')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ left: 8 })
        .layoutWeight(1)

      // 模型切换按钮
      Button(this.getModelName())
        .fontSize(11)
        .height(28)
        .backgroundColor('#E8F4FD')
        .fontColor('#1E90FF')
        .borderRadius(14)
        .onClick(() => { this.showModelPicker = true })

      // 新建对话
      Text('+')
        .fontSize(22)
        .fontColor('#1E90FF')
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8 })
        .onClick(async () => {
          let convId = await ChatService.getInstance().createConversation('新对话', ModelType.GENERAL)
          this.conversationId = convId
          this.messages = []
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildWelcomeTips() {
    Column() {
      Text('👋 你好！我是智慧文旅助手')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 40, bottom: 20 })

      Column() {
        this.buildTipChip('景点讲解', '帮我介绍一下故宫的历史')
        this.buildTipChip('路线规划', '帮我规划北京三日游路线')
        this.buildTipChip('美食推荐', '推荐西安的特色美食')
        this.buildTipChip('住宿推荐', '推荐杭州西湖附近的酒店')
        this.buildTipChip('天气穿搭', '今天北京天气怎么样，穿什么合适')
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildTipChip(title: string, prompt: string) {
    Row() {
      Text(title)
        .fontSize(12)
        .fontColor('#1E90FF')
      Text(`: ${prompt}`)
        .fontSize(12)
        .fontColor('#666666')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('90%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.inputText = prompt
      this.sendMessage()
    })
  }

  @Builder
  buildMessageBubble(item: MessageItem) {
    Row() {
      if (item.role === MessageRole.USER) {
        Blank()
      }

      Column() {
        if (item.role === MessageRole.ASSISTANT) {
          // AI 头像
          Text('AI')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .width(28)
            .height(28)
            .backgroundColor('#1E90FF')
            .borderRadius(14)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 2 })
        }

        Text(item.content)
          .fontSize(14)
          .fontColor(item.role === MessageRole.USER ? '#FFFFFF' : '#333333')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(item.role === MessageRole.USER ? '#1E90FF' : '#FFFFFF')
          .borderRadius(12)
          .constraintSize({ maxWidth: '75%' })
          .textAlign(TextAlign.Start)
          .gesture(
            LongPressGesture()
              .onAction(() => {
                if (item.role === MessageRole.ASSISTANT) {
                  this.selectedMessage = item
                  this.showActionSheet = true
                }
              })
          )
      }
      .alignItems(item.role === MessageRole.USER ? HorizontalAlign.End : HorizontalAlign.Start)

      if (item.role === MessageRole.ASSISTANT) {
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .justifyContent(item.role === MessageRole.USER ? FlexAlign.End : FlexAlign.Start)
  }

  @Builder
  buildStreamingBubble() {
    Row() {
      Text('AI')
        .fontSize(11)
        .fontColor('#FFFFFF')
        .width(28)
        .height(28)
        .backgroundColor('#1E90FF')
        .borderRadius(14)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 2 })

      Text(this.streamingContent + '|')
        .fontSize(14)
        .fontColor('#333333')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .constraintSize({ maxWidth: '75%' })
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  buildInputBar() {
    Row() {
      TextInput({ placeholder: '输入您的问题...', text: this.inputText })
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .fontSize(14)
        .onChange((value: string) => { this.inputText = value })
        .enabled(!this.isStreaming)

      Button('发送')
        .fontSize(13)
        .height(36)
        .backgroundColor(this.isStreaming ? '#CCCCCC' : '#1E90FF')
        .fontColor('#FFFFFF')
        .borderRadius(18)
        .margin({ left: 8 })
        .enabled(!this.isStreaming && this.inputText.trim().length > 0)
        .onClick(() => { this.sendMessage() })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildModelPicker() {
    Column() {
      Column() {
        Text('选择模型')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding(16)
          .textAlign(TextAlign.Center)

        ForEach(MODEL_CONFIGS, (config: ModelConfig) => {
          Row() {
            Text(config.name)
              .fontSize(14)
              .fontColor(this.currentModelType === config.type ? '#1E90FF' : '#333333')
              .layoutWeight(1)
            if (this.currentModelType === config.type) {
              Text('✓')
                .fontSize(18)
                .fontColor('#1E90FF')
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .onClick(() => {
            this.currentModelType = config.type
            ChatService.getInstance().setCurrentModel(config.type)
            this.showModelPicker = false
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
          .onClick(() => { this.showModelPicker = false })
      }
      .width('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showModelPicker = false })
  }

  @Builder
  buildActionSheet() {
    Column() {
      Column() {
        Text('操作')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding(16)
          .textAlign(TextAlign.Center)

        Button('收藏此内容')
          .width('90%')
          .height(44)
          .fontSize(14)
          .backgroundColor('#E8F4FD')
          .fontColor('#1E90FF')
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onClick(() => { this.addToFavorites() })

        Button('加入行程清单')
          .width('90%')
          .height(44)
          .fontSize(14)
          .backgroundColor('#FFF3E0')
          .fontColor('#FF9800')
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onClick(() => { this.addToTrip() })

        Button('取消')
          .width('90%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .borderRadius(8)
          .margin({ bottom: 16 })
          .onClick(() => { this.showActionSheet = false })
      }
      .width('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#40000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showActionSheet = false })
  }

  /**
   * 发送消息
   */
  async sendMessage(): Promise<void> {
    let text = this.inputText.trim()
    if (text.length === 0 || this.isStreaming) return

    this.inputText = ''
    this.isLoading = true

    try {
      // 确保对话存在
      if (this.conversationId === 0) {
        this.conversationId = await ChatService.getInstance().createConversation('新对话', ModelType.GENERAL)
      }

      // 添加用户消息到列表
      let userMsgId = await ChatService.getInstance().saveMessage(this.conversationId, MessageRole.USER, text)
      this.messages.push({
        id: userMsgId,
        role: MessageRole.USER,
        content: text,
        isStreaming: false,
        createTime: Date.now()
      })

      // 更新对话标题（失败不影响发送）
      try {
        if (this.messages.length <= 2) {
          let title = text.length > 15 ? text.substring(0, 15) + '...' : text
          await ChatService.getInstance().updateConversation(this.conversationId, title, '')
        }
      } catch (err) {
        // 无关紧要
      }

      this.scrollToBottom()

      // 如果是天气相关问题，先查询天气
      let contextMessages = await this.buildContextMessages(text)

      // 流式发送
      this.isStreaming = true
      this.streamingContent = ''

      ChatService.getInstance().sendStreamMessage(
        this.conversationId,
        contextMessages,
        (delta: string) => {
          this.streamingContent += delta
          this.scrollToBottom()
        },
        async (fullContent: string) => {
          // 保存助手消息
          let assistantMsgId = await ChatService.getInstance().saveMessage(
            this.conversationId, MessageRole.ASSISTANT, fullContent
          )
          this.messages.push({
            id: assistantMsgId,
            role: MessageRole.ASSISTANT,
            content: fullContent,
            isStreaming: false,
            createTime: Date.now()
          })
          this.streamingContent = ''
          this.isStreaming = false
          this.isLoading = false

          // 更新对话摘要
          let summary = fullContent.length > 50 ? fullContent.substring(0, 50) + '...' : fullContent
          await ChatService.getInstance().updateConversation(this.conversationId, '', summary)
        },
        (error: string) => {
          this.isStreaming = false
          this.isLoading = false
          promptAction.showToast({ message: error, duration: 2000 })
        }
      )
    } catch (err) {
      this.isStreaming = false
      this.isLoading = false
      let errObj = err as Error
      promptAction.showToast({ message: '发送失败: ' + (errObj.message || JSON.stringify(err)), duration: 3000 })
    }
  }

  async buildContextMessages(userText: string): Promise<Record<string, string>[]> {
    let messages: Record<string, string>[] = []

    // 系统提示词
    let systemPrompt = '你是一个智慧文旅助手，擅长景点讲解、游玩路线规划、特色美食推荐、住宿推荐和天气穿搭建议。请用中文回答，内容详细且实用。'

    messages.push({ 'role': 'system', 'content': systemPrompt })

    // 检测是否是天气相关查询
    if (userText.includes('天气') || userText.includes('穿搭') || userText.includes('穿什么')) {
      try {
        let weather = await WeatherService.getInstance().getWeather('北京', 'all')
        let weatherText = WeatherService.getInstance().formatWeatherForAI(weather)
        messages.push({
          'role': 'system',
          'content': `当前天气信息如下：\n${weatherText}\n请根据以上天气信息，回答用户问题。`
        })
      } catch (err) {
        // 天气查询失败不影响对话
      }
    }

    // 历史上下文
    let history = await ChatService.getInstance().buildContext(this.conversationId, 20)
    for (let h of history) {
      messages.push(h)
    }

    return messages
  }

  async addToFavorites(): Promise<void> {
    if (!this.selectedMessage) return
    this.showActionSheet = false
    try {
      await FavoriteService.getInstance().addFavorite(
        this.selectedMessage.id,
        this.conversationId,
        this.selectedMessage.content,
        'spot_explanation'
      )
      promptAction.showToast({ message: '已收藏', duration: 1500 })
    } catch (err) {
      promptAction.showToast({ message: '收藏失败', duration: 1500 })
    }
  }

  async addToTrip(): Promise<void> {
    if (!this.selectedMessage) return
    this.showActionSheet = false
    try {
      await TripService.getInstance().createTrip(
        '行程项目',
        '',
        1,
        this.selectedMessage.content
      )
      promptAction.showToast({ message: '已加入行程清单', duration: 1500 })
    } catch (err) {
      promptAction.showToast({ message: '添加失败', duration: 1500 })
    }
  }

  scrollToBottom(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    }, 100)
  }

  getModelName(): string {
    let config = MODEL_CONFIGS.find(c => c.type === this.currentModelType)
    return config ? config.name : '选择模型'
  }
}