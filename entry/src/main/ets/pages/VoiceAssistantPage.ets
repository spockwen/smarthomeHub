import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'

interface VoiceCommand {
  id: string
  command: string
  description: string
  icon: string
}

@Entry
@Component
struct VoiceAssistantPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State isVoiceEnabled: boolean = true
  @State wakeWord: string = '小智小智'
  @State language: string = '中文（普通话）'
  @State responseSpeed: string = '标准'
  @State showWakeWordDialog: boolean = false

  private quickCommands: VoiceCommand[] = [
    { id: '1', command: '打开客厅灯', description: '控制客厅灯光开关', icon: '💡' },
    { id: '2', command: '空调设为26度', description: '调节空调温度', icon: '❄️' },
    { id: '3', command: '打开回家模式', description: '执行温馨回家场景', icon: '🏠' },
    { id: '4', command: '关闭所有灯', description: '关闭全部灯光设备', icon: '🌙' },
    { id: '5', command: '门锁已锁定吗', description: '查询门锁状态', icon: '🔐' },
    { id: '6', command: '今天能耗多少', description: '查询今日能耗数据', icon: '⚡' }
  ]

  build() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            router.back()
          })

        Text('语音助手')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('  ')
          .fontSize(FontSize.BODY2)
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.LG, right: Spacing.LG })
      .backgroundColor(ThemeColors.surface(this.isDark))

      Scroll() {
        Column({ space: Spacing.LG }) {
          Column({ space: Spacing.MD }) {
            Row() {
              Text('🎤')
                .fontSize(48)

              Column({ space: 4 }) {
                Text(this.isVoiceEnabled ? '语音助手已启用' : '语音助手已关闭')
                  .fontSize(FontSize.BODY1)
                  .fontWeight(600)
                  .fontColor(ThemeColors.textPrimary(this.isDark))

                Text('唤醒词：' + this.wakeWord)
                  .fontSize(FontSize.CAPTION1)
                  .fontColor(ThemeColors.textSecondary(this.isDark))
              }
              .margin({ left: Spacing.MD })
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.isVoiceEnabled })
                .selectedColor(Colors.BRAND_PRIMARY)
                .width(48)
                .height(28)
                .onChange((isOn: boolean) => {
                  this.isVoiceEnabled = isOn
                })
            }
            .width('100%')
            .padding(Spacing.XL)
            .borderRadius(BorderRadius.LARGE)
            .backgroundColor(ThemeColors.surface(this.isDark))
          }
          .padding({ left: Spacing.LG, right: Spacing.LG })

          Column({ space: Spacing.MD }) {
            Text('语音设置')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: 2 }) {
              Row() {
                Text('唤醒词')
                  .fontSize(FontSize.BODY1)
                  .fontColor(ThemeColors.textPrimary(this.isDark))

                Blank()

                Text(this.wakeWord)
                  .fontSize(FontSize.BODY2)
                  .fontColor(ThemeColors.textSecondary(this.isDark))
                  .margin({ right: Spacing.SM })

                Text('>')
                  .fontSize(16)
                  .fontColor(ThemeColors.textTertiary(this.isDark))
              }
              .width('100%')
              .padding(Spacing.LG)
              .backgroundColor(ThemeColors.surface(this.isDark))
              .onClick(() => {
                prompt.showToast({ message: '唤醒词设置功能开发中' })
              })

              Row() {
                Text('语音语言')
                  .fontSize(FontSize.BODY1)
                  .fontColor(ThemeColors.textPrimary(this.isDark))

                Blank()

                Text(this.language)
                  .fontSize(FontSize.BODY2)
                  .fontColor(ThemeColors.textSecondary(this.isDark))
                  .margin({ right: Spacing.SM })

                Text('>')
                  .fontSize(16)
                  .fontColor(ThemeColors.textTertiary(this.isDark))
              }
              .width('100%')
              .padding(Spacing.LG)
              .backgroundColor(ThemeColors.surface(this.isDark))

              Row() {
                Text('响应速度')
                  .fontSize(FontSize.BODY1)
                  .fontColor(ThemeColors.textPrimary(this.isDark))

                Blank()

                Text(this.responseSpeed)
                  .fontSize(FontSize.BODY2)
                  .fontColor(ThemeColors.textSecondary(this.isDark))
                  .margin({ right: Spacing.SM })

                Text('>')
                  .fontSize(16)
                  .fontColor(ThemeColors.textTertiary(this.isDark))
              }
              .width('100%')
              .padding(Spacing.LG)
              .backgroundColor(ThemeColors.surface(this.isDark))
            }
            .borderRadius(BorderRadius.LARGE)
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Column({ space: Spacing.MD }) {
            Text('快捷语音指令')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: Spacing.SM }) {
              ForEach(this.quickCommands, (cmd: VoiceCommand) => {
                Row() {
                  Text(cmd.icon)
                    .fontSize(24)
                    .margin({ right: Spacing.MD })

                  Column({ space: 4 }) {
                    Text('"' + cmd.command + '"')
                      .fontSize(FontSize.BODY1)
                      .fontColor(ThemeColors.textPrimary(this.isDark))

                    Text(cmd.description)
                      .fontSize(FontSize.CAPTION1)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding(Spacing.LG)
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(ThemeColors.surface(this.isDark))
              })
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Row() {
            Text('🎤')
              .fontSize(24)
              .fontColor('#FFFFFF')
          }
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor(Colors.BRAND_PRIMARY)
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 12, color: Colors.BRAND_PRIMARY + '40', offsetX: 0, offsetY: 4 })
          .alignSelf(ItemAlign.Center)
          .margin({ top: Spacing.LG, bottom: Spacing.LG })
          .onClick(() => {
            prompt.showToast({ message: '语音识别功能演示中...' })
          })
        }
        .width('100%')
        .padding({ top: Spacing.LG, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
