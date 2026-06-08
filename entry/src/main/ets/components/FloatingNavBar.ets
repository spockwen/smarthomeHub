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

  build() {
    Row() {
      ForEach(this.items, (item: NavItemModel, index: number) => {
        Text(item.title)
          .fontSize(14)
          .fontWeight(index === this.selectedIndex ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(index === this.selectedIndex ? '#007DFF' : '#99182431')
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
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .shadow({
      radius: 20,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
  }
}