import { AIService, ChatMessage } from '../service/AIService'
import { ThemeColors, FontSize, Spacing, BorderRadius } from '../common/DesignConstants'
import { DeviceStore } from '../DeviceStore'

interface ChatItem {
  id: number
  role: 'user' | 'assistant' | 'system'
  content: string
  time: number
}

interface DeviceCommand {
  storeMethod: string
  value: boolean
  displayName: string
  keywords: string[]
}

@Component
export struct AIChatPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State userInput: string = ''
  @State chatList: ChatItem[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''

  private aiService: AIService = AIService.getInstance()
  private chatHistory: ChatMessage[] = []
  private chatId: number = 0
  private isFirstAppear: boolean = true

  private readonly sceneKeywords: Record<string, string[]> = {
    'home': ['回家', '回家模式', '回家场景', '到家'],
    'leave': ['离家', '离家模式', '离家场景', '出门'],
    'sleep': ['睡眠', '睡眠模式', '睡眠场景', '睡觉', '晚安'],
    'movie': ['观影', '观影模式', '观影场景', '看电影', '电影模式']
  }

  private readonly sceneNames: Record<string, string> = {
    'home': '回家模式',
    'leave': '离家模式',
    'sleep': '睡眠模式',
    'movie': '观影模式'
  }

  private readonly deviceCommands: DeviceCommand[] = [
    { keywords: ['客厅灯', '开灯', '打开灯', '灯光开'], storeMethod: 'setLightOn', value: true, displayName: '客厅灯已打开' },
    { keywords: ['关灯', '关闭灯', '灯关'], storeMethod: 'setLightOn', value: false, displayName: '客厅灯已关闭' },
    { keywords: ['卧室灯'], storeMethod: 'setBedroomLightOn', value: true, displayName: '卧室灯已打开' },
    { keywords: ['关卧室灯'], storeMethod: 'setBedroomLightOn', value: false, displayName: '卧室灯已关闭' },
    { keywords: ['厨房灯'], storeMethod: 'setKitchenLightOn', value: true, displayName: '厨房灯已打开' },
    { keywords: ['关厨房灯'], storeMethod: 'setKitchenLightOn', value: false, displayName: '厨房灯已关闭' },
    { keywords: ['开空调', '打开空调'], storeMethod: 'setAirOn', value: true, displayName: '空调已打开' },
    { keywords: ['关空调', '关闭空调'], storeMethod: 'setAirOn', value: false, displayName: '空调已关闭' },
    { keywords: ['开地暖', '打开地暖'], storeMethod: 'setHeaterOn', value: true, displayName: '地暖已打开' },
    { keywords: ['关地暖', '关闭地暖'], storeMethod: 'setHeaterOn', value: false, displayName: '地暖已关闭' },
    { keywords: ['开门', '解锁', '开锁'], storeMethod: 'setDoorLocked', value: false, displayName: '门锁已解锁' },
    { keywords: ['锁门', '上锁'], storeMethod: 'setDoorLocked', value: true, displayName: '门锁已上锁' },
    { keywords: ['打开窗帘', '拉开窗帘', '开窗帘'], storeMethod: 'setCurtainOpen', value: true, displayName: '窗帘已打开' },
    { keywords: ['关闭窗帘', '拉上窗帘', '关窗帘'], storeMethod: 'setCurtainOpen', value: false, displayName: '窗帘已关闭' },
    { keywords: ['开摄像头', '开监控'], storeMethod: 'setCameraOn', value: true, displayName: '摄像头已开启' },
    { keywords: ['关摄像头', '关监控'], storeMethod: 'setCameraOn', value: false, displayName: '摄像头已关闭' },
    { keywords: ['开插座', '打开插座'], storeMethod: 'setSocketOn', value: true, displayName: '智能插座已开启' },
    { keywords: ['关插座', '关闭插座'], storeMethod: 'setSocketOn', value: false, displayName: '智能插座已关闭' },
    { keywords: ['开电视', '打开电视'], storeMethod: 'setTvOn', value: true, displayName: '电视已打开' },
    { keywords: ['关电视', '关闭电视'], storeMethod: 'setTvOn', value: false, displayName: '电视已关闭' }
  ]

  aboutToAppear(): void {
    const saved = AppStorage.get<string>('aiChatHistory') || ''
    if (saved.length > 0 && this.isFirstAppear) {
      try {
        const items: ChatItem[] = JSON.parse(saved) as ChatItem[]
        if (items.length > 0) {
          this.chatList = items
          this.chatId = items[items.length - 1].id + 1
          this.isFirstAppear = false
          return
        }
      } catch (_e) {
      }
    }
    if (this.isFirstAppear) {
      this.addChatItem('assistant', '您好！我是鸿蒙智家 AI 助手。您可以询问我关于智能家居的问题，或者让我帮您控制设备，比如："帮我打开客厅灯"、"启动回家模式"。')
      this.isFirstAppear = false
    }
  }

  aboutToDisappear(): void {
    this.saveChatHistory()
  }

  private saveChatHistory(): void {
    try {
      AppStorage.set('aiChatHistory', JSON.stringify(this.chatList))
    } catch (_e) {
    }
  }

  private addChatItem(role: 'user' | 'assistant' | 'system', content: string): void {
    this.chatList.push({
      id: this.chatId++,
      role: role,
      content: content,
      time: Date.now()
    })
    this.saveChatHistory()
  }

  private parseAndExecuteCommand(input: string): string[] {
    const results: string[] = []
    const lowerInput = input

    for (const sceneId of Object.keys(this.sceneKeywords)) {
      const keywords = this.sceneKeywords[sceneId]
      for (const kw of keywords) {
        if (lowerInput.includes(kw)) {
          const isActive = AppStorage.get<string>('activeScene') === sceneId
          if (isActive) {
            results.push(`${this.sceneNames[sceneId]}已经是开启状态`)
          } else {
            DeviceStore.triggerScene(sceneId)
            results.push(`已为您启动${this.sceneNames[sceneId]}：相关设备已自动调整`)
          }
          return results
        }
      }
    }

    for (const cmd of this.deviceCommands) {
      for (const kw of cmd.keywords) {
        if (lowerInput.includes(kw)) {
          this.executeDeviceCommand(cmd.storeMethod, cmd.value)
          results.push(cmd.displayName)
          break
        }
      }
      if (results.length > 0) {
        break
      }
    }

    return results
  }

  private executeDeviceCommand(method: string, value: boolean): void {
    if (method === 'setLightOn') {
      DeviceStore.setLightOn(value)
    } else if (method === 'setBedroomLightOn') {
      DeviceStore.setBedroomLightOn(value)
    } else if (method === 'setKitchenLightOn') {
      DeviceStore.setKitchenLightOn(value)
    } else if (method === 'setAirOn') {
      DeviceStore.setAirOn(value)
    } else if (method === 'setHeaterOn') {
      DeviceStore.setHeaterOn(value)
    } else if (method === 'setDoorLocked') {
      DeviceStore.setDoorLocked(value)
    } else if (method === 'setCurtainOpen') {
      DeviceStore.setCurtainOpen(value)
    } else if (method === 'setCameraOn') {
      DeviceStore.setCameraOn(value)
    } else if (method === 'setSocketOn') {
      DeviceStore.setSocketOn(value)
    } else if (method === 'setTvOn') {
      DeviceStore.setTvOn(value)
    }
  }

  async handleSend(): Promise<void> {
    const input = this.userInput.trim()
    if (!input || this.isLoading) {
      return
    }

    this.userInput = ''
    this.errorMessage = ''
    this.addChatItem('user', input)

    const commandResults = this.parseAndExecuteCommand(input)

    if (commandResults.length > 0) {
      const confirmMsg = commandResults.join('；')
      this.addChatItem('system', confirmMsg)

      try {
        this.isLoading = true
        const response = await this.aiService.smartHomeChat(input, this.chatHistory)
        const cleanResponse = this.removeThinkTags(response)
        this.addChatItem('assistant', cleanResponse)
        this.chatHistory.push(new ChatMessage('user', input))
        this.chatHistory.push(new ChatMessage('assistant', cleanResponse))
        if (this.chatHistory.length > 20) {
          this.chatHistory = this.chatHistory.slice(-20)
        }
      } catch (_error) {
      } finally {
        this.isLoading = false
      }
      return
    }

    this.isLoading = true
    try {
      const response = await this.aiService.smartHomeChat(input, this.chatHistory)
      const cleanResponse = this.removeThinkTags(response)
      this.addChatItem('assistant', cleanResponse)
      this.chatHistory.push(new ChatMessage('user', input))
      this.chatHistory.push(new ChatMessage('assistant', cleanResponse))
      if (this.chatHistory.length > 20) {
        this.chatHistory = this.chatHistory.slice(-20)
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : '未知错误'
      this.addChatItem('assistant', `抱歉，AI服务暂时不可用。请稍后再试。\n错误信息: ${errorMsg}`)
    } finally {
      this.isLoading = false
    }
  }

  private removeThinkTags(content: string): string {
    let result = content.replace(/<note>[\s\S]*?<\/note>/g, '')
    result = result.replace(/<tool_call>[\s\S]*?<\/think>/g, '')
    return result.trim()
  }

  private startNewChat(): void {
    this.chatList = []
    this.chatHistory = []
    this.chatId = 0
    this.addChatItem('assistant', '您好！我是鸿蒙智家 AI 助手。新的对话已开始，您可以继续询问我关于智能家居的问题。')
    AppStorage.set('aiChatHistory', '')
  }

  build() {
    Column() {
      Row() {
        Text('🤖 AI助手')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .layoutWeight(1)

        Row({ space: 4 }) {
          Text('新对话')
            .fontSize(FontSize.CAPTION1)
            .fontColor('#007DFF')
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(BorderRadius.MEDIUM)
        .backgroundColor(this.isDark ? '#1A007DFF' : '#0A007DFF')
        .onClick(() => {
          if (this.chatList.length <= 1) {
            this.startNewChat()
          } else {
            AlertDialog.show({
              title: '新建对话',
              message: '开启新对话将清除当前聊天记录，是否继续？',
              primaryButton: {
                value: '取消',
                action: () => {}
              },
              secondaryButton: {
                value: '新建',
                action: () => {
                  this.startNewChat()
                }
              }
            })
          }
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor('#FF6B6B')
          .margin({ top: 10 })
          .padding(10)
          .backgroundColor(this.isDark ? '#3D1F1F' : '#FFF0F0')
          .borderRadius(8)
          .width('90%')
      }

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.chatList, (item: ChatItem) => {
            this.chatBubble(item)
          })

          if (this.isLoading) {
            Row() {
              LoadingProgress()
                .width(24)
                .height(24)
              Text(' AI思考中...')
                .fontSize(14)
                .fontColor(ThemeColors.textTertiary(this.isDark))
            }
            .width('100%')
            .padding(12)
            .backgroundColor(ThemeColors.itemBg(this.isDark))
            .borderRadius(12)
          }
        }
        .width('100%')
        .padding({ bottom: 10 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)

      Row({ space: 10 }) {
        TextInput({
          placeholder: '请输入您的问题',
          text: this.userInput
        })
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .placeholderColor(ThemeColors.textTertiary(this.isDark))
          .backgroundColor(ThemeColors.surface(this.isDark))
          .borderRadius(20)
          .onChange((value) => {
            this.userInput = value
          })
          .onSubmit(() => {
            this.handleSend()
          })
          .flexShrink(1)

        Button('发送')
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleSend()
          })
      }
      .width('90%')
      .margin({ top: 10, bottom: 80 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }

  @Builder
  chatBubble(item: ChatItem) {
    Row() {
      if (item.role !== 'user') {
        Text(item.role === 'system' ? '⚙️' : '🤖')
          .fontSize(20)
          .margin({ right: 8 })
          .flexShrink(0)
      }

      Column({ space: 4 }) {
        if (item.role === 'system') {
          Text('操作确认')
            .fontSize(FontSize.CAPTION1)
            .fontColor('#007DFF')
            .fontWeight(500)
        }
        Text(item.content)
          .fontSize(16)
          .textAlign(item.role === 'user' ? TextAlign.End : TextAlign.Start)
          .fontColor(item.role === 'system' ? '#007DFF' : ThemeColors.textPrimary(this.isDark))
          .wordBreak(WordBreak.BREAK_WORD)
      }
      .alignItems(item.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
      .constraintSize({ maxWidth: '75%' })
      .padding(12)
      .backgroundColor(
        item.role === 'system' ? (this.isDark ? '#1A007DFF' : '#0A007DFF') :
        item.role === 'user' ? ThemeColors.selectedBg(this.isDark) :
        ThemeColors.itemBg(this.isDark)
      )
      .borderRadius(12)

      if (item.role === 'user') {
        Text('👤')
          .fontSize(20)
          .margin({ left: 8 })
          .flexShrink(0)
      }
    }
    .width('100%')
    .justifyContent(item.role === 'user' ? FlexAlign.End : FlexAlign.Start)
    .alignItems(VerticalAlign.Top)
  }
}
