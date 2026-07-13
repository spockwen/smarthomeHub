import { ThemeColors, Colors, GlowConfig, BorderRadius } from '../common/DesignConstants'

export interface NavItemModel {
  title: string
}

@Component
export struct FloatingNavBar {
  @Prop items: NavItemModel[] = []
  @Prop selectedIndex: number = 0
  private onIndexChange?: (index: number) => void
  @StorageProp('isDarkMode') isDark: boolean = false

  @State private isPressed: boolean = false
  @State private pressedIndex: number = -1
  @State private glowScale: number = 1
  @State private glowOpacity: number = 0

  build() {
    Row() {
      ForEach(this.items, (item: NavItemModel, index: number) => {
        Column() {
          Text(item.title)
            .fontSize(index === this.selectedIndex ? 15 : 14)
            .fontWeight(index === this.selectedIndex ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(index === this.selectedIndex ? '#007DFF' : (this.isDark ? '#CCFFFFFF' : '#99182431'))

          Row()
            .width(16)
            .height(3)
            .borderRadius(2)
            .backgroundColor('#007DFF')
            .margin({ top: 4 })
            .opacity(index === this.selectedIndex ? 0.9 : 0)
            .shadow({
              radius: index === this.selectedIndex ? 6 : 0,
              color: '#4D007DFF',
              offsetX: 0,
              offsetY: 0
            })
        }
        .padding({ top: 10, bottom: 10 })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(16)
        .scale({
          x: (this.isPressed && this.pressedIndex === index) ? 0.92 : 1,
          y: (this.isPressed && this.pressedIndex === index) ? 0.92 : 1
        })
        .animation({ duration: 150, curve: Curve.Sharp })
        .onClick(() => {
          if (this.onIndexChange) {
            this.onIndexChange(index)
          }
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.isPressed = true
            this.pressedIndex = index
            this.glowScale = 1.2
            this.glowOpacity = 0.3
            setTimeout(() => {
              this.glowScale = 1.4
              this.glowOpacity = 0.15
            }, 80)
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.isPressed = false
            this.pressedIndex = -1
            this.glowScale = 1
            this.glowOpacity = 0
          }
        })
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .borderRadius(28)
    .backgroundColor(this.isDark ? 'rgba(26, 26, 26, 0.55)' : 'rgba(255, 255, 255, 0.55)')
    .backgroundBlurStyle(BlurStyle.Thin, {
      colorMode: this.isDark ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
      adaptiveColor: AdaptiveColor.DEFAULT,
      scale: 0.85
    })
    .borderWidth(0.5)
    .borderColor(this.isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)')
    .shadow({
      radius: 16,
      color: this.isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 4
    })
    .brightness(this.isPressed ? 1.08 : 1)
    .animation({ duration: 200, curve: Curve.EaseOut })
  }
}
