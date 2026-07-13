import router from '@ohos.router'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'

interface AboutInfo {
  label: string
  value: string
}

@Entry
@Component
struct AboutPage {
  @StorageProp('isDarkMode') isDark: boolean = false

  private appInfo: AboutInfo[] = [
    { label: '应用名称', value: '鸿蒙智家 AI Hub' },
    { label: '版本号', value: 'v1.0.0' },
    { label: '构建版本', value: '2025.07.10' },
    { label: '平台', value: 'OpenHarmony' },
    { label: '开发框架', value: 'ArkTS + ArkUI' },
    { label: '适用设备', value: '手机/平板/智慧屏' }
  ]

  private teamInfo: AboutInfo[] = [
    { label: '团队', value: '代码诗人队' },
    { label: '项目', value: 'AI全屋智能控制平台' },
    { label: '技术栈', value: 'HarmonyOS + AI' }
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

        Text('关于')
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
            Text('🏠')
              .fontSize(64)

            Text('鸿蒙智家 AI Hub')
              .fontSize(FontSize.TITLE1)
              .fontWeight(700)
              .fontColor(ThemeColors.textPrimary(this.isDark))

            Text('v1.0.0')
              .fontSize(FontSize.BODY1)
              .fontColor(ThemeColors.textSecondary(this.isDark))
          }
          .width('100%')
          .padding(Spacing.XL)
          .alignItems(HorizontalAlign.Center)

          Column({ space: Spacing.MD }) {
            Text('应用信息')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: 0 }) {
              ForEach(this.appInfo, (info: AboutInfo, index: number) => {
                Row() {
                  Text(info.label)
                    .fontSize(FontSize.BODY1)
                    .fontColor(ThemeColors.textSecondary(this.isDark))

                  Blank()

                  Text(info.value)
                    .fontSize(FontSize.BODY2)
                    .fontColor(ThemeColors.textPrimary(this.isDark))
                }
                .width('100%')
                .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
              })
            }
            .width('100%')
            .borderRadius(BorderRadius.LARGE)
            .backgroundColor(ThemeColors.surface(this.isDark))
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Column({ space: Spacing.MD }) {
            Text('开发团队')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: 0 }) {
              ForEach(this.teamInfo, (info: AboutInfo) => {
                Row() {
                  Text(info.label)
                    .fontSize(FontSize.BODY1)
                    .fontColor(ThemeColors.textSecondary(this.isDark))

                  Blank()

                  Text(info.value)
                    .fontSize(FontSize.BODY2)
                    .fontColor(ThemeColors.textPrimary(this.isDark))
                }
                .width('100%')
                .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
              })
            }
            .width('100%')
            .borderRadius(BorderRadius.LARGE)
            .backgroundColor(ThemeColors.surface(this.isDark))
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Column({ space: Spacing.SM }) {
            Text('基于 OpenHarmony 的 AI 全屋智能控制平台')
              .fontSize(FontSize.CAPTION1)
              .fontColor(ThemeColors.textTertiary(this.isDark))
              .textAlign(TextAlign.Center)

            Text('融合设备控制、场景自动化、AI对话、商城购物于一体')
              .fontSize(FontSize.CAPTION1)
              .fontColor(ThemeColors.textTertiary(this.isDark))
              .textAlign(TextAlign.Center)

            Text('代码诗人参赛项目')
              .fontSize(FontSize.CAPTION1)
              .fontColor(ThemeColors.textTertiary(this.isDark))
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(Spacing.XL)
          .alignItems(HorizontalAlign.Center)

          Row() {
            Text('检查更新')
              .fontSize(FontSize.BODY1)
              .fontColor('#FFFFFF')
              .fontWeight(600)
          }
          .width('90%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .borderRadius(24)
          .backgroundColor(Colors.BRAND_PRIMARY)
          .margin({ left: '5%' })
          .onClick(() => {
            AlertDialog.show({
              title: '检查更新',
              message: '当前已是最新版本 v1.0.0'
            })
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
