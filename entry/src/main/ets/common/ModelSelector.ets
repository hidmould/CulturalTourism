import { ModelConfig, DEFAULT_MODELS } from '../model/ChatModel'

/**
 * 模型选择器组件
 */
@Component
export struct ModelSelector {
  @Prop selectedModelType: string = 'general'
  onModelChange?: (modelType: string) => void
  private models: ModelConfig[] = DEFAULT_MODELS

  build() {
    Row() {
      ForEach(this.models, (model: ModelConfig) => {
        Text(model.displayName)
          .fontSize(13)
          .fontColor(model.type === this.selectedModelType ? '#FFF' : '#007AFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(model.type === this.selectedModelType ? '#007AFF' : '#E8F0FE')
          .margin({ right: 8 })
          .onClick(() => {
            if (this.onModelChange) {
              this.onModelChange(model.type)
            }
          })
      })
    }
    .padding({ left: 4, right: 4 })
  }
}