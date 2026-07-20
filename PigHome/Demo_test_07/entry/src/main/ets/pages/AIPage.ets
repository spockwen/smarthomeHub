// ============================================================
// 【AI助手】页面 - AIPage.ets
// 对话界面 + 快捷指令 + 语音/文字输入 + 流式输出
// 可控制【家庭】页所有设备的开关与调节
// ============================================================

import { ChatMessage } from '../model/DeviceModel'
import {
  toggleDevice,
  adjustDevice,
  executeScene,
  toggleAllLights,
  isDeviceOn,
  saveChatHistory,
  loadChatHistory
} from '../service/DeviceStateService'
import { sendToggleCommand, sendAdjustCommand, sendSceneCommand } from '../service/MqttService'

interface QuickCmd {
  label: string
  cmd: string
}

const QUICK_CMDS: QuickCmd[] = [
  { label: '打开所有灯', cmd: '打开所有灯' },
  { label: '空调调到24度', cmd: '空调调到24度' },
  { label: '开启离家模式', cmd: '开启离家模式' },
  { label: '今日用电情况', cmd: '今日用电情况' }
]

// 支持的设备名列表（用于自然语言匹配）
const DEVICE_NAMES: string[] = [
  '客厅主灯', '书房灯', '油烟机', '空气净化器',
  '空调', '电动窗帘', '窗帘', '投影仪', '智能门锁',
  '所有灯', '灯'
]

// 从用户输入中提取数字
function extractNumber(input: string): number | null {
  const match = input.match(/(\d+)/)
  return match ? parseInt(match[1], 10) : null
}

// 从用户输入中匹配设备名
function matchDevice(input: string): string | null {
  for (const name of DEVICE_NAMES) {
    if (input.includes(name)) return name
  }
  return null
}

// 解析并执行用户指令，返回 AI 回复文本
function parseAndExecuteCommand(input: string): string {
  const trimmed = input.trim()

  // ── 场景模式 ──
  if (trimmed.includes('离家模式') || trimmed.includes('离家')) {
    sendSceneCommand('离家模式')
    return executeScene('离家模式')
  }
  if (trimmed.includes('回家模式') || trimmed.includes('回家')) {
    sendSceneCommand('回家模式')
    return executeScene('回家模式')
  }

  // ── 用电查询 ──
  if (trimmed.includes('用电')) {
    return '今日用电 12.4 kWh，较昨日节省 8%，预估费用 ¥8.9 ⚡'
  }

  // ── 开关控制 ──
  const turnOn = trimmed.includes('打开') || trimmed.includes('开启') || trimmed.includes('开灯')
  const turnOff = trimmed.includes('关闭') || trimmed.includes('关掉') || trimmed.includes('关灯') || trimmed.includes('关上')

  // 特殊处理"关灯"→识别为所有灯关闭
  if (trimmed === '关灯' || trimmed === '关闭所有灯') {
    AppStorage.Set('isLightOn', false)
    AppStorage.Set('isStudyLightOn', false)
    AppStorage.Set('isStudyLightLevel', 0)
    sendToggleCommand('客厅主灯', false)
    sendToggleCommand('书房灯', false)
    return '已为您关闭全部灯光 🌙'
  }

  const deviceName = matchDevice(trimmed)

  if (deviceName) {
    if (turnOn || turnOff) {
      if (deviceName === '所有灯' || deviceName === '灯') {
        if (turnOn || trimmed.includes('开灯')) {
          sendToggleCommand('客厅主灯', true)
          sendToggleCommand('书房灯', true)
          return toggleAllLights()
        } else {
          AppStorage.Set('isLightOn', false)
          AppStorage.Set('isStudyLightOn', false)
          AppStorage.Set('isStudyLightLevel', 0)
          sendToggleCommand('客厅主灯', false)
          sendToggleCommand('书房灯', false)
          return '已为您关闭全部灯光 🌙'
        }
      }
      // 智能门锁特殊逻辑
      if (deviceName === '智能门锁') {
        if (turnOn || trimmed.includes('开')) {
          AppStorage.Set('isDoorLocked', false)
          sendToggleCommand('智能门锁', true)
          return '门锁已解锁 🔓'
        } else {
          AppStorage.Set('isDoorLocked', true)
          sendToggleCommand('智能门锁', false)
          return '门锁已锁定 🔒'
        }
      }
      const toggleResult = toggleDevice(deviceName)
      sendToggleCommand(deviceName, isDeviceOn(deviceName))
      return toggleResult
    }

    // ── 调节参数 ──
    const number = extractNumber(trimmed)
    if (number !== null && (trimmed.includes('调到') || trimmed.includes('设定') || trimmed.includes('设置') || trimmed.includes('调整'))) {
      const result = adjustDevice(deviceName, number)
      // 将 '窗帘' 映射为 '电动窗帘' 以匹配 MQTT 设备名
      const mqttName = deviceName === '窗帘' ? '电动窗帘' : deviceName
      sendAdjustCommand(mqttName, number)
      return result.message
    }

    // 只提到设备名但无明确操作
    const status = isDeviceOn(deviceName) ? '已开启 ✅' : '已关闭 ❌'
    return `当前「${deviceName}」${status}`
  }

  // ── 空调快捷指令 ──
  if (trimmed.includes('空调')) {
    const number = extractNumber(trimmed)
    if (number !== null) {
      const result = adjustDevice('空调', number)
      sendAdjustCommand('空调', number)
      return result.message
    }
    return `当前空调${AppStorage.Get<boolean>('isACOn') ? '已开启 ❄️ 温度' + AppStorage.Get<number>('acTemp') + '℃' : '已关闭 ❌'}`
  }

  // ── 窗帘快捷指令 ──
  if (trimmed.includes('窗帘')) {
    const number = extractNumber(trimmed)
    if (number !== null) {
      const result = adjustDevice('电动窗帘', number)
      sendAdjustCommand('电动窗帘', number)
      return result.message
    }
    return `当前窗帘${AppStorage.Get<boolean>('isCurtainOn') ? '已打开 🪟 开合度' + AppStorage.Get<number>('curtainLevel') + '%' : '已关闭 ❌'}`
  }

  // ── 未知指令 ──
  return `收到！我暂时无法理解「${trimmed}」😅\n试试说：打开空调、关闭客厅主灯、空调调到26度、离家模式`
}

function now(): string {
  const d = new Date()
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
}

@Entry
@Component
export struct AIPage {
  @State messages: ChatMessage[] = []
  @State inputText: string = ''
  @State showHistory: boolean = false
  @State isVoiceMode: boolean = false         // true=按住说话，false=键盘输入
  @State isSpeaking: boolean = false          // 是否正在按住说话
  private scrollController: Scroller = new Scroller()

  sendMessage(text: string) {
    if (text.trim() === '') return

    // 用户新输入时：仅保留本次对话（旧记录已持久化）
    this.messages = []
    this.showHistory = true

    const userMsg: ChatMessage = {
      id: `u_${Date.now()}`,
      role: 'user',
      content: text.trim(),
      time: now()
    }
    this.messages = [...this.messages, userMsg]
    this.inputText = ''
    this.scrollController.scrollEdge(Edge.Bottom)

    // 模拟AI延迟后流式输出
    setTimeout(() => {
      const fullReply: string = parseAndExecuteCommand(text)
      const aiId: string = `a_${Date.now()}`
      const aiTime: string = now()

      // 先插入空消息（isStreaming = true）
      const emptyMsg: ChatMessage = {
        id: aiId,
        role: 'ai',
        content: '',
        time: aiTime,
        isStreaming: true
      }
      this.messages = [...this.messages, emptyMsg]
      this.scrollController.scrollEdge(Edge.Bottom)

      // 逐字追加（打字机效果）
      let charIdx: number = 0
      const timer: number = setInterval(() => {
        charIdx++
        const partial: string = fullReply.substring(0, charIdx)
        const done: boolean = charIdx >= fullReply.length

        this.messages = this.messages.map((m: ChatMessage) => {
          if (m.id === aiId) {
            const updated: ChatMessage = {
              id: m.id,
              role: m.role,
              content: done ? fullReply : partial,
              time: m.time,
              isStreaming: !done
            }
            return updated
          }
          return m
        })
        this.scrollController.scrollEdge(Edge.Bottom)

        if (done) {
          clearInterval(timer)
          // 流式完成后，将本次对话追加到持久化历史
          this.appendToHistory(userMsg, {
            id: aiId,
            role: 'ai',
            content: fullReply,
            time: aiTime
          })
        }
      }, 40) // 每40ms输出一个字
    }, 600)

    this.scrollController.scrollEdge(Edge.Bottom)
  }

  /** 将一组对话（用户 + AI）追加到持久化历史记录 */
  async appendToHistory(user: ChatMessage, ai: ChatMessage): Promise<void> {
    const history = await loadChatHistory()
    history.push(user, ai)
    await saveChatHistory(history)
  }

  /** 加载历史聊天记录并展示 */
  async toggleHistory(): Promise<void> {
    this.showHistory = !this.showHistory
    if (this.showHistory) {
      const history = await loadChatHistory()
      this.messages = history
    } else {
      // 收起历史 → 清空对话列表，回到欢迎界面
      this.messages = []
    }
  }

  // 切换语音/键盘模式
  toggleInputMode() {
    this.isVoiceMode = !this.isVoiceMode
    this.inputText = ''
  }

  build() {
    Column() {

      // ======== 顶部标题栏 ========
      Row() {
        Text('AI 助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Blank()

        Text(this.showHistory ? '收起历史记录' : '展开历史记录')
          .fontSize(13)
          .fontColor('#4080FF')
          .backgroundColor('#EEF3FF')
          .borderRadius(8)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .onClick(() => { this.toggleHistory() })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      // ======== 对话区域 ========
      if (!this.showHistory) {
        // 空状态：居中引导
        Column({ space: 12 }) {
          // AI头像
          Column() {
            Text('🤖')
              .fontSize(40)
          }
          .width(90)
          .height(90)
          .backgroundColor('#7C5CFC')
          .borderRadius(45)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .shadow({ radius: 20, color: '#7C5CFC40', offsetX: 0, offsetY: 8 })

          Text('你好，有什么可以帮您？')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')

          Text('说出指令或输入文字，我来帮你控制')
            .fontSize(13)
            .fontColor('#888888')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else {
        // 有消息时：气泡对话列表
        Scroll(this.scrollController) {
          Column({ space: 12 }) {
            ForEach(this.messages, (msg: ChatMessage) => {
              if (msg.role === 'user') {
                // ---- 用户消息：右对齐 ----
                Row() {
                  Blank()
                  Column() {
                    Text(msg.content)
                      .fontSize(14)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#4080FF')
                      .borderRadius(14)
                      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                      .constraintSize({ maxWidth: 220 })
                    Text(msg.time)
                      .fontSize(10)
                      .fontColor('#AAAAAA')
                      .margin({ top: 4 })
                      .alignSelf(ItemAlign.End)
                  }
                  .alignItems(HorizontalAlign.End)
                }
                .width('100%')
              } else {
                // ---- AI消息：左对齐（含流式光标） ----
                Row({ space: 8 }) {
                  Text('🤖')
                    .fontSize(20)
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .backgroundColor('#7C5CFC')
                    .borderRadius(18)

                  Column() {
                    Row({ space: 0 }) {
                      Text(msg.content)
                        .fontSize(14)
                        .fontColor('#1A1A1A')
                        .backgroundColor('#F0F0F0')
                        .borderRadius(14)
                        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                        .constraintSize({ maxWidth: 220 })

                      // ---- 流式输出光标：仅 AI 正在输出时显示 ----
                      if (msg.isStreaming) {
                        Text('▊')
                          .fontSize(14)
                          .fontColor('#7C5CFC')
                          .margin({ left: -6 })
                          .alignSelf(ItemAlign.End)
                          .transition({ type: TransitionType.Insert, opacity: 0 })
                      }
                    }

                    Text(msg.time)
                      .fontSize(10)
                      .fontColor('#AAAAAA')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .alignItems(VerticalAlign.Bottom)
              }
            })
            Blank().height(8)
          }
          .padding({ left: 20, right: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      // ======== 快捷指令区 ========
      Scroll() {
        Row({ space: 8 }) {
          ForEach(QUICK_CMDS, (q: QuickCmd) => {
            Text(q.label)
              .fontSize(12)
              .fontColor('#555555')
              .backgroundColor('#F0F0F0')
              .borderRadius(20)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => { this.sendMessage(q.cmd) })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      // ======== 底部输入栏 ========
      Row({ space: 10 }) {
        if (this.isVoiceMode) {
          // ────── 语音模式：⌨️键盘 + [按住说话] ──────
          // 最左：键盘图标（点击切回文字模式）
          Text('⌨️')
            .fontSize(20)
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F0F0F0')
            .borderRadius(22)
            .onClick(() => { this.toggleInputMode() })

          // 中间：按住说话按钮
          Button() {
            Text(this.isSpeaking ? '松开 发送' : '按住 说话')
              .fontSize(14)
              .fontColor(this.isSpeaking ? '#FFFFFF' : '#666666')
              .fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor(this.isSpeaking ? '#4080FF' : '#F0F0F0')
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.isSpeaking = true
            } else if (event.type === TouchType.Up) {
              this.isSpeaking = false
              // 模拟语音识别发送"打开所有灯"
              this.sendMessage('打开所有灯')
            }
          })
        } else {
          // ────── 文字模式：输入框 + 🎤麦克风 ──────
          // 文本输入框
          TextInput({ placeholder: '输入消息或指令...', text: this.inputText })
            .fontSize(14)
            .layoutWeight(1)
            .height(44)
            .borderRadius(22)
            .backgroundColor('#F0F0F0')
            .padding({ left: 16, right: 16 })
            .onChange((val: string) => { this.inputText = val })
            .onSubmit(() => { this.sendMessage(this.inputText) })

          // 语音按钮（点击切换到语音模式）
          Text('🎤')
            .fontSize(20)
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F0F0F0')
            .borderRadius(22)
            .onClick(() => { this.toggleInputMode() })
        }

        // ────── 发送按钮（始终在右侧不动）──────
        Text('↑')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.inputText.trim() || this.isVoiceMode ? '#4080FF' : '#CCCCCC')
          .borderRadius(22)
          .onClick(() => {
            if (this.isVoiceMode) {
              this.sendMessage('打开所有灯')
            } else {
              this.sendMessage(this.inputText)
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
