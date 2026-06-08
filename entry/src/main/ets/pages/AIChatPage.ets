import { AIService, ChatMessage } from '../service/AIService'

interface ChatItem {
  id: number
  role: 'user' | 'assistant'
  content: string
  time: number
}

@Component
export struct AIChatPage {
  @State userInput: string = ''
  @State chatList: ChatItem[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''

  private aiService: AIService = AIService.getInstance()
  private chatHistory: ChatMessage[] = []
  private chatId: number = 0

  aboutToAppear(): void {
    // 添加初始欢迎消息
    this.addChatItem('assistant', '您好！我是鸿蒙智家 AI 助手。您可以询问我关于智能家居的问题，或者让我帮您控制设备，比如："帮我打开客厅灯"或"空调调低到24度"。')
  }

  addChatItem(role: 'user' | 'assistant', content: string): void {
    this.chatList.push({
      id: this.chatId++,
      role: role,
      content: content,
      time: Date.now()
    })
  }

  async handleSend(): Promise<void> {
    const input = this.userInput.trim()
    if (!input || this.isLoading) {
      return
    }

    // 清空输入框
    this.userInput = ''
    this.errorMessage = ''

    // 添加用户消息
    this.addChatItem('user', input)

    // 显示加载状态
    this.isLoading = true

    try {
      // 调用 AI 服务
      const response = await this.aiService.smartHomeChat(input, this.chatHistory)

      // 添加 AI 回复
      this.addChatItem('assistant', response)

      // 更新对话历史
      this.chatHistory.push(new ChatMessage('user', input))
      this.chatHistory.push(new ChatMessage('assistant', response))

      // 保持历史不超过 20 条
      if (this.chatHistory.length > 20) {
        this.chatHistory = this.chatHistory.slice(-20)
      }
    } catch (error) {
      // 显示错误消息
      const errorMsg = error instanceof Error ? error.message : '未知错误'
      this.errorMessage = `抱歉，AI服务暂时不可用: ${errorMsg}`
      this.addChatItem('assistant', `抱歉，AI服务暂时不可用。请稍后再试。\n错误信息: ${errorMsg}`)
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 标题
      Text('🤖 AI助手')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor('#FF6B6B')
          .margin({ top: 10 })
          .padding(10)
          .backgroundColor('#FFF0F0')
          .borderRadius(8)
          .width('90%')
      }

      // 聊天区域
      Scroll() {
        Column({ space: 12 }) {
          ForEach(
            this.chatList,
            (item: ChatItem) => {
              this.chatBubble(item)
            }
          )

          // 加载指示器
          if (this.isLoading) {
            Row() {
              LoadingProgress()
                .width(24)
                .height(24)
              Text(' AI思考中...')
                .fontSize(14)
                .fontColor('#999')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
          }
        }
        .width('100%')
        .padding({ bottom: 10 })
      }
      .height('60%')
      .width('100%')
      .scrollBar(BarState.Auto)

      // 输入区域
      Row({ space: 10 }) {
        TextInput({
          placeholder: '请输入您的问题',
          text: this.userInput
        })
          .onChange((value) => {
            this.userInput = value
          })
          .onSubmit(() => {
            this.handleSend()
          })
          .flexShrink(1)

        Button('发送')
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleSend()
          })
      }
      .width('90%')
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  @Builder
  chatBubble(item: ChatItem) {
    Row() {
      Text(item.role === 'user' ? '👤' : '🤖')
        .fontSize(20)
        .margin({ right: 8 })

      Text(item.content)
        .fontSize(16)
        .layoutWeight(1)
        .textAlign(item.role === 'user' ? TextAlign.End : TextAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(item.role === 'user' ? '#E3F2FD' : '#F5F5F5')
    .borderRadius(12)
    .alignItems(VerticalAlign.Top)
  }
}