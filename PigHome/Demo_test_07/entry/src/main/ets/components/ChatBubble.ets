// ============================================================
// 聊天气泡组件 - ChatBubble.ets
// 用于【AI助手】页面的对话列表
// 复用方式：
//   ChatBubble({ message })
//   ChatBubble({ message, showAvatar: false })
// ============================================================

import { ChatMessage } from '../model/DeviceModel'

@Component
export struct ChatBubble {
  @Prop message: ChatMessage
  @Prop showAvatar: boolean = true   // AI气泡左侧是否显示头像

  build() {
    if (this.message.role === 'user') {
      // ---- 用户消息：右对齐蓝色气泡 ----
      Row() {
        Blank()
        Column() {
          Text(this.message.content)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#4080FF')
            .borderRadius(14)
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .constraintSize({ maxWidth: 220 })

          Text(this.message.time)
            .fontSize(10)
            .fontColor('#AAAAAA')
            .margin({ top: 4 })
            .alignSelf(ItemAlign.End)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

    } else {
      // ---- AI消息：左对齐白色气泡 ----
      Row({ space: 8 }) {
        // AI 头像
        if (this.showAvatar) {
          Text('🤖')
            .fontSize(20)
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .backgroundColor('#7C5CFC')
            .borderRadius(18)
        }

        Column() {
          Text(this.message.content)
            .fontSize(14)
            .fontColor('#1A1A1A')
            .backgroundColor('#F0F0F0')
            .borderRadius(14)
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .constraintSize({ maxWidth: 220 })

          Text(this.message.time)
            .fontSize(10)
            .fontColor('#AAAAAA')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
  }
}
