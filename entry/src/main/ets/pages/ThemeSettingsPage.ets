import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import { DeviceStore } from '../DeviceStore'
import router from '@ohos.router'

interface ThemeOption {
  id: string
  icon: string
  title: string
  subtitle: string
}

@Entry
@Component
struct ThemeSettingsPage {
  @StorageLink('themeMode') themeMode: string = 'follow-system'
  @StorageProp('isDarkMode') isDark: boolean = false

  private readonly options: ThemeOption[] = [
    { id: 'light', icon: '☀️', title: '浅色模式', subtitle: '始终使用浅色主题' },
    { id: 'dark', icon: '🌙', title: '深色模式', subtitle: '始终使用深色主题' },
    { id: 'follow-system', icon: '🔄', title: '跟随系统', subtitle: '自动切换浅色/深色' }
  ]

  private selectTheme(mode: string): void {
    DeviceStore.setThemeMode(mode)
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

        Text('主题设置')
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
            Text('选择主题模式')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: 2 }) {
              ForEach(this.options, (option: ThemeOption) => {
                Row() {
                  Text(option.icon)
                    .fontSize(28)
                    .margin({ right: Spacing.LG })

                  Column({ space: 4 }) {
                    Text(option.title)
                      .fontSize(FontSize.BODY1)
                      .fontWeight(500)
                      .fontColor(ThemeColors.textPrimary(this.isDark))

                    Text(option.subtitle)
                      .fontSize(FontSize.CAPTION1)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  if (this.themeMode === option.id) {
                    Text('✓')
                      .fontSize(20)
                      .fontColor(Colors.BRAND_PRIMARY)
                      .fontWeight(700)
                  }
                }
                .width('100%')
                .padding(Spacing.LG)
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(ThemeColors.surface(this.isDark))
                .onClick(() => {
                  this.selectTheme(option.id)
                })
              })
            }
            .width('100%')
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Column({ space: Spacing.MD }) {
            Text('预览效果')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Row() {
              Column({ space: Spacing.SM }) {
                Text('☀️ 浅色')
                  .fontSize(FontSize.BODY2)
                  .fontColor(ThemeColors.textPrimary(false))

                Column()
                  .width(60)
                  .height(40)
                  .borderRadius(8)
                  .backgroundColor(Colors.BG_LIGHT)
                  .border({ width: 1, color: '#1A000000' })
              }
              .padding(Spacing.MD)
              .borderRadius(BorderRadius.LARGE)
              .backgroundColor(ThemeColors.surface(this.isDark))
              .border({
                width: 2,
                color: !this.isDark ? Colors.BRAND_PRIMARY : 'transparent'
              })

              Column({ space: Spacing.SM }) {
                Text('🌙 深色')
                  .fontSize(FontSize.BODY2)
                  .fontColor(ThemeColors.textPrimary(true))

                Column()
                  .width(60)
                  .height(40)
                  .borderRadius(8)
                  .backgroundColor(Colors.BG_DARK)
                  .border({ width: 1, color: '#24FFFFFF' })
              }
              .padding(Spacing.MD)
              .borderRadius(BorderRadius.LARGE)
              .backgroundColor(ThemeColors.surface(this.isDark))
              .border({
                width: 2,
                color: this.isDark ? Colors.BRAND_PRIMARY : 'transparent'
              })
            }
            .width('100%')
            .padding({ left: Spacing.LG, right: Spacing.LG })
            .justifyContent(FlexAlign.SpaceEvenly)
          }
        }
        .width('100%')
        .padding({ top: Spacing.LG, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
