/**
 * SSE 数据块接口
 */
interface SseChunk {
  choices?: SseChoice[]
}

interface SseChoice {
  delta?: SseDelta
}

interface SseDelta {
  content?: string
}

/**
 * SSE 流式数据解析器
 * 解析 Server-Sent Events 格式的数据
 */
export class SseParser {
  private buffer: string = ''
  private onData: (text: string) => void
  private onDone: () => void
  private onError: (error: string) => void

  constructor(
    onData: (text: string) => void,
    onDone: () => void,
    onError: (error: string) => void
  ) {
    this.onData = onData
    this.onDone = onDone
    this.onError = onError
  }

  /**
   * 推送收到的数据块，逐行解析SSE
   */
  push(chunk: string): void {
    this.buffer += chunk
    this.parseLines()
  }

  /**
   * 标记流结束，处理剩余buffer
   */
  finish(): void {
    this.parseLines()
    this.onDone()
  }

  private parseLines(): void {
    if (!this.buffer) {
      return
    }

    const lines = this.buffer.split('\n')
    // 保留最后一个可能不完整的行
    this.buffer = lines.pop() || ''

    for (const line of lines) {
      const trimmed = line.trim()
      if (!trimmed) {
        continue
      }

      // SSE 格式: "data: {...}"
      if (trimmed.startsWith('data: ')) {
        const dataStr = trimmed.substring(6)
        if (dataStr === '[DONE]') {
          this.onDone()
          return
        }
        try {
          const parsed: SseChunk = JSON.parse(dataStr) as SseChunk
          const delta = this.extractDelta(parsed)
          if (delta) {
            this.onData(delta)
          }
        } catch (_) {
          // 非JSON数据，直接传递
          if (dataStr) {
            this.onData(dataStr)
          }
        }
      }
    }
  }

  /**
   * 从OpenAI兼容格式的响应中提取delta文本
   */
  private extractDelta(data: SseChunk): string {
    try {
      const choices = data.choices
      if (choices && choices.length > 0) {
        const delta = choices[0].delta
        if (delta && delta.content) {
          return delta.content
        }
      }
    } catch (_) {
      // ignore
    }
    return ''
  }
}

/**
 * 模拟流式数据（用于开发测试，当API不可用时）
 */
export class MockStreamService {

  static getMockResponse(input: string): string {
    if (input.includes('景点') || input.includes('旅游')) {
      return MockStreamService.getSpotResponse()
    }
    if (input.includes('美食') || input.includes('吃') || input.includes('推荐')) {
      return MockStreamService.getFoodResponse()
    }
    if (input.includes('路线') || input.includes('行程') || input.includes('规划')) {
      return MockStreamService.getRouteResponse()
    }
    if (input.includes('天气') || input.includes('穿搭') || input.includes('穿')) {
      return MockStreamService.getWeatherResponse()
    }
    return MockStreamService.getDefaultResponse()
  }

  private static getSpotResponse(): string {
    return '这里为您介绍几个著名景点：\n\n1. **故宫博物院** - 位于北京，是中国明清两代的皇家宫殿，世界文化遗产。建议游览时间3-4小时。\n\n2. **西湖** - 位于杭州，以"淡妆浓抹总相宜"闻名，免费开放，建议骑行环湖。\n\n3. **兵马俑** - 位于西安，世界第八大奇迹，建议上午前往避开人流。'
  }

  private static getFoodResponse(): string {
    return '为您推荐以下特色美食：\n\n1. **北京烤鸭** - 推荐全聚德、便宜坊，外酥里嫩\n2. **重庆火锅** - 推荐佩姐老火锅、洞子火锅\n3. **广州早茶** - 推荐点都德、陶陶居\n4. **成都串串** - 推荐冒椒火辣、马路边边'
  }

  private static getRouteResponse(): string {
    return '为您规划一条3天短途旅行路线：\n\n**Day 1**：抵达目的地 → 入住酒店 → 市区漫步 → 品尝当地美食\n**Day 2**：上午游览核心景点 → 下午文化体验 → 晚上夜市探索\n**Day 3**：周边自然风光 → 购买特产 → 返程'
  }

  private static getWeatherResponse(): string {
    return '当前天气查询结果：\n\n温度：22°C ~ 28°C\n天气：多云转晴\n建议：适合出行，建议穿薄外套，携带防晒用品。'
  }

  private static getDefaultResponse(): string {
    return '您好！我是文旅小智，很高兴为您服务。\n\n我可以帮您：\n- 景点讲解\n- 路线规划\n- 美食推荐\n- 住宿建议\n- 天气穿搭\n\n请问有什么可以帮您的？'
  }

  /**
   * 模拟流式输出，逐字推送
   */
  static simulateStream(
    input: string,
    onData: (text: string) => void,
    onDone: () => void
  ): void {
    const response = MockStreamService.getMockResponse(input)
    let index = 0
    const timer = setInterval(() => {
      if (index < response.length) {
        onData(response[index])
        index++
      } else {
        clearInterval(timer)
        onDone()
      }
    }, 30)
  }
}