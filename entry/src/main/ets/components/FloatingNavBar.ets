import { ThemeColors } from '../common/DesignConstants'

// 导航项数据模型
export interface NavItemModel {
  title: string
}

// 悬浮导航栏组件 - 纯文字版
@Component
export struct FloatingNavBar {
  @Prop items: NavItemModel[] = []
  @Prop selectedIndex: number = 0
  private onIndexChange?: (index: number) => void
  @StorageProp('isDarkMode') isDark: boolean = false

  build() {
    Row() {
      ForEach(this.items, (item: NavItemModel, index: number) => {
        Text(item.title)
          .fontSize(14)
          .fontWeight(index === this.selectedIndex ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(index === this.selectedIndex ? '#007DFF' : (this.isDark ? '#99FFFFFF' : '#99182431'))
          .padding({ top: 12, bottom: 12 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.onIndexChange) {
              this.onIndexChange(index)
            }
          })
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isDark ? '#1A1A1A' : '#FFFFFF')
    .borderRadius(24)
    .shadow({
      radius: 20,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 4
    })
  }
}
