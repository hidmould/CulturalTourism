/**
 * 消息气泡通用组件
 */
@Component
export struct MessageBubble {
  @Prop role: string = 'user'   // 'user' | 'assistant'
  @Prop content: string = ''
  @Prop isStreaming: boolean = false
  @Prop isFavorite: boolean = false
  onFavorite?: () => void
  onAddToTrip?: () => void

  build() {
    Row() {
      if (this.role === 'user') {
        Blank()
      }

      Column() {
        // 角色标签
        Text(this.role === 'user' ? '我' : '文旅小智')
          .fontSize(12)
          .fontColor('#999')
          .margin({ bottom: 4 })

        // 消息内容
        Text(this.content || (this.isStreaming ? '思考中...' : ''))
          .fontSize(15)
          .fontColor(this.role === 'user' ? '#FFF' : '#333')
          .padding(12)
          .borderRadius(12)
          .backgroundColor(this.role === 'user' ? '#007AFF' : '#F0F0F0')
          .constraintSize({ maxWidth: '80%' })

        // 助手消息的操作按钮
        if (this.role === 'assistant' && this.content && !this.isStreaming) {
          Row() {
            Button() {
              Text(this.isFavorite ? '★ 已收藏' : '☆ 收藏')
                .fontSize(12)
                .fontColor(this.isFavorite ? '#FF9500' : '#666')
            }
            .type(ButtonType.Normal)
            .backgroundColor(Color.Transparent)
            .height(28)
            .onClick(() => {
              if (this.onFavorite) {
                this.onFavorite()
              }
            })

            Button() {
              Text('+ 行程')
                .fontSize(12)
                .fontColor('#666')
            }
            .type(ButtonType.Normal)
            .backgroundColor(Color.Transparent)
            .height(28)
            .onClick(() => {
              if (this.onAddToTrip) {
                this.onAddToTrip()
              }
            })
          }
          .margin({ top: 4 })
        }

        // 流式输出中的光标
        if (this.isStreaming) {
          Text('▍')
            .fontSize(14)
            .fontColor('#007AFF')
            .margin({ top: 2 })
        }
      }
      .alignItems(this.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)

      if (this.role === 'assistant') {
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}