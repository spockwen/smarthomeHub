import { DeviceStore } from '../DeviceStore'

@Component
export struct AIChatPage {
  @State userInput: string = ''
  @State aiReply: string = '您好，我是鸿蒙智家 AI 助手'
  @State chatList: string[] = ['🤖：您好，我是鸿蒙智家 AI 助手']
  
  // 使用 @StorageLink 双向绑定全局状态，自动同步
  @StorageLink('lightOn') lightOn: boolean = true
  @StorageLink('airOn') airOn: boolean = false

  build() {
    Column() {

      Text('🤖 AI助手')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      Scroll() {
        Column({ space: 10 }) {

          ForEach(
            this.chatList,
            (item: string) => {
              Text(item)
                .fontSize(16)
                .width('100%')
            }
          )

        }
        .width('100%')
      }
      .height('60%')
      .width('100%')

      TextInput({
        placeholder: '请输入您的指令'
      })
        .onChange((value) => {
          this.userInput = value
        })
        .width('90%')

      Button('发送')
        .margin({ top: 20 })
        .onClick(() => {
          this.handleAI()
        })

    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  handleAI() {

    if (this.userInput.includes('太热')) {
      DeviceStore.setAirOn(true)
      this.aiReply = '已为您打开空调，并设置为24℃'
    }
    else if (this.userInput.includes('开灯')) {
      DeviceStore.setLightOn(true)
      this.aiReply = '已打开客厅灯'
    }
    else if (this.userInput.includes('关灯')) {
      DeviceStore.setLightOn(false)
      this.aiReply = '已关闭客厅灯'
    }
    else if (this.userInput.includes('回家')) {
      this.aiReply = '已执行回家模式'
    }
    else if (this.userInput.includes('离家')) {
      this.aiReply = '已执行离家模式'
    }
    else if (this.userInput.includes('睡觉')) {
      this.aiReply = '已切换睡眠模式'
    }
    else if (this.userInput.includes('打开空调')) {
      DeviceStore.setAirOn(true)
      this.aiReply = '已打开空调'
    }
    else if (this.userInput.includes('关闭空调')) {
      DeviceStore.setAirOn(false)
      this.aiReply = '已关闭空调'
    }
    else {
      this.aiReply = '抱歉，我暂时无法理解该指令'
    }
    this.chatList.push('👤：' + this.userInput)
    this.chatList.push('🤖：' + this.aiReply)

    this.userInput = ''
  }
}
