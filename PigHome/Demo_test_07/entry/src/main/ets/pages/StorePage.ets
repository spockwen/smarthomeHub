// ============================================================
// 【商城】页面 - StorePage.ets
// 分类导航 + 推荐产品网格
// ============================================================

interface Category {
  id: string
  name: string
  icon: string
}

interface Product {
  id: string
  name: string
  icon: string
  price: number
  originalPrice: number
}

const CATEGORIES: Category[] = [
  { id: 'light',   name: '照明', icon: '💡' },
  { id: 'ac',      name: '空调', icon: '❄️' },
  { id: 'security',name: '安防', icon: '🔒' },
  { id: 'av',      name: '影音', icon: '📺' },
  { id: 'clean',   name: '清洁', icon: '🤖' },
  { id: 'env',     name: '环境', icon: '🌿' }
]

const PRODUCTS: Product[] = [
  { id: 'p1', name: '智能吸顶灯 Pro', icon: '💡', price: 299, originalPrice: 499 },
  { id: 'p2', name: '门口摄像头',      icon: '📷', price: 399, originalPrice: 599 },
  { id: 'p3', name: '温湿度传感器',    icon: '🌡️', price: 79,  originalPrice: 129 },
  { id: 'p4', name: '智能插排 6孔',    icon: '🔌', price: 149, originalPrice: 229 }
]

@Entry
@Component
export struct StorePage {
  @State searchText: string = ''

  build() {
    Column() {

      // ======== 顶部标题 ========
      Row() {
        Text('商城')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Blank()

        Text('🔍')
          .fontSize(22)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F0F0F0')
          .borderRadius(10)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })

      Scroll() {
        Column({ space: 0 }) {

          // ======== Banner ========
          Column() {
            Text('智家新品季')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('Matter 互联 · 全屋联动')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.8)')
              .margin({ top: 4 })
          }
          .width('100%')
          .height(120)
          .backgroundColor('#1A2A5E')
          .borderRadius(16)
          .justifyContent(FlexAlign.End)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 20, bottom: 20 })
          .margin({ left: 20, right: 20, bottom: 20 })

          // ======== 品类导航 ========
          Text('品类')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .padding({ left: 20, bottom: 12 })

          Row({ space: 0 }) {
            ForEach(CATEGORIES, (cat: Category) => {
              Column({ space: 6 }) {
                Text(cat.icon)
                  .fontSize(24)
                  .width(52)
                  .height(52)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#F0F2FF')
                  .borderRadius(14)

                Text(cat.name)
                  .fontSize(12)
                  .fontColor('#444444')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 24 })

          // ======== 推荐产品 ========
          Text('推荐')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .padding({ left: 20, bottom: 12 })

          // 2列网格
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(PRODUCTS, (p: Product) => {
              Column({ space: 0 }) {
                // 产品图片区
                Text(p.icon)
                  .fontSize(48)
                  .width('100%')
                  .height(130)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(12)

                // 产品信息
                Column({ space: 4 }) {
                  Text(p.name)
                    .fontSize(13)
                    .fontColor('#1A1A1A')
                    .fontWeight(FontWeight.Medium)
                    .maxLines(2)

                  Row({ space: 6 }) {
                    Text(`¥${p.price}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF4D4F')

                    Text(`¥${p.originalPrice}`)
                      .fontSize(12)
                      .fontColor('#AAAAAA')
                      .decoration({ type: TextDecorationType.LineThrough })
                  }
                  .alignItems(VerticalAlign.Bottom)
                }
                .padding({ top: 10, bottom: 10 })
                .alignItems(HorizontalAlign.Start)
              }
              .width('47%')
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 12 })
              .margin({ bottom: 12 })
              .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })
            })
          }
          .padding({ left: 20, right: 20 })

          Blank().height(20)
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}
