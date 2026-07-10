import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'

interface FAQItem {
  question: string
  answer: string
  icon: string
}

@Entry
@Component
struct HelpFeedbackPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State feedbackText: string = ''
  @State contactInfo: string = ''
  @State expandedFAQ: number = -1

  private faqList: FAQItem[] = [
    { question: '如何添加新设备？', answer: '进入"我的设备"页面，点击右上角"+ 添加"按钮，按照提示完成设备配网和绑定。确保设备已通电并处于配网模式。', icon: '📱' },
    { question: '设备离线怎么办？', answer: '1. 检查设备是否通电\n2. 确认WiFi网络是否正常\n3. 尝试重启设备\n4. 如仍无法连接，请删除设备重新配网', icon: '📡' },
    { question: '如何创建自动化场景？', answer: '进入"场景"页面，点击"创建场景"按钮，设置触发条件和执行动作即可。支持定时、位置、设备状态等多种触发方式。', icon: '🎬' },
    { question: '语音助手无法识别怎么办？', answer: '1. 确保语音助手已启用\n2. 使用正确的唤醒词\n3. 说话时距离设备1-3米\n4. 环境噪音较大时可能影响识别', icon: '🎤' },
    { question: '如何分享设备给家人？', answer: '进入"家庭管理"页面，点击"邀请"按钮，通过链接或二维码邀请家人加入家庭，即可共享设备控制权限。', icon: '🏠' },
    { question: '数据安全如何保障？', answer: '所有数据传输采用TLS 1.3加密，本地数据采用AES-256加密存储，支持双因素身份验证，确保您的隐私和数据安全。', icon: '🔐' }
  ]

  submitFeedback(): void {
    if (this.feedbackText.trim().length === 0) {
      prompt.showToast({ message: '请输入反馈内容' })
      return
    }
    prompt.showToast({ message: '感谢您的反馈，我们会尽快处理' })
    this.feedbackText = ''
    this.contactInfo = ''
  }

  build() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            router.back()
          })

        Text('帮助与反馈')
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
              Text('📖')
                .fontSize(32)
                .margin({ right: Spacing.MD })

              Text('常见问题')
                .fontSize(FontSize.BODY1)
                .fontWeight(600)
                .fontColor(ThemeColors.textPrimary(this.isDark))
            }
            .width('100%')
            .padding({ left: Spacing.LG })

            Column({ space: Spacing.SM }) {
              ForEach(this.faqList, (faq: FAQItem, index: number) => {
                Column() {
                  Row() {
                    Text(faq.icon)
                      .fontSize(24)
                      .margin({ right: Spacing.MD })

                    Text(faq.question)
                      .fontSize(FontSize.BODY1)
                      .fontColor(ThemeColors.textPrimary(this.isDark))
                      .layoutWeight(1)

                    Text(this.expandedFAQ === index ? '∧' : '∨')
                      .fontSize(14)
                      .fontColor(ThemeColors.textTertiary(this.isDark))
                  }
                  .width('100%')
                  .padding(Spacing.LG)
                  .onClick(() => {
                    this.expandedFAQ = this.expandedFAQ === index ? -1 : index
                  })

                  if (this.expandedFAQ === index) {
                    Text(faq.answer)
                      .fontSize(FontSize.BODY2)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                      .lineHeight(22)
                      .padding({ left: Spacing.XXL, right: Spacing.LG, bottom: Spacing.LG })
                  }
                }
                .width('100%')
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(ThemeColors.surface(this.isDark))
              })
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Column({ space: Spacing.MD }) {
            Text('意见反馈')
              .fontSize(FontSize.BODY1)
              .fontWeight(600)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: Spacing.MD }) {
              TextArea({ placeholder: '请描述您遇到的问题或建议', text: this.feedbackText })
                .placeholderColor(ThemeColors.textTertiary(this.isDark))
                .fontColor(ThemeColors.textPrimary(this.isDark))
                .fontSize(FontSize.BODY2)
                .backgroundColor(ThemeColors.itemBg(this.isDark))
                .borderRadius(BorderRadius.MEDIUM)
                .width('100%')
                .height(120)
                .padding(Spacing.MD)
                .onChange((value: string) => {
                  this.feedbackText = value
                })

              TextInput({ placeholder: '联系方式（选填）', text: this.contactInfo })
                .placeholderColor(ThemeColors.textTertiary(this.isDark))
                .fontColor(ThemeColors.textPrimary(this.isDark))
                .fontSize(FontSize.BODY2)
                .backgroundColor(ThemeColors.itemBg(this.isDark))
                .borderRadius(BorderRadius.MEDIUM)
                .width('100%')
                .height(44)
                .padding({ left: Spacing.MD, right: Spacing.MD })
                .onChange((value: string) => {
                  this.contactInfo = value
                })

              Row() {
                Text('提交反馈')
                  .fontSize(FontSize.BODY1)
                  .fontColor('#FFFFFF')
                  .fontWeight(600)
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.Center)
              .borderRadius(24)
              .backgroundColor(Colors.BRAND_PRIMARY)
              .onClick(() => {
                this.submitFeedback()
              })
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Column({ space: Spacing.MD }) {
            Text('联系我们')
              .fontSize(FontSize.BODY1)
              .fontWeight(600)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: Spacing.SM }) {
              Row() {
                Text('📞')
                  .fontSize(24)
                  .margin({ right: Spacing.MD })
                Text('客服电话：400-888-9999')
                  .fontSize(FontSize.BODY2)
                  .fontColor(ThemeColors.textPrimary(this.isDark))
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(Spacing.LG)
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(ThemeColors.surface(this.isDark))

              Row() {
                Text('📧')
                  .fontSize(24)
                  .margin({ right: Spacing.MD })
                Text('邮箱：support@smarthome.com')
                  .fontSize(FontSize.BODY2)
                  .fontColor(ThemeColors.textPrimary(this.isDark))
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(Spacing.LG)
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(ThemeColors.surface(this.isDark))
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }
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
