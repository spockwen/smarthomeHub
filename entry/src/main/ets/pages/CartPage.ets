// 购物车页面 - 符合 ArkTS 规范
import prompt from '@ohos.promptAction'
import { CartService } from '../service/CartService'
import { CartItem } from '../service/ProductService'

// 主题色常量接口
interface ColorConfig {
  BRAND: string
  SUCCESS: string
  WARNING: string
  ERROR: string
  TEXT_PRIMARY: string
  TEXT_SECONDARY: string
  TEXT_TERTIARY: string
  BORDER: string
  BACKGROUND: string
  WHITE: string
}

// 间距常量接口
interface SpacingConfig {
  SM: number
  MD: number
  LG: number
  XL: number
}

const Colors: ColorConfig = {
  BRAND: '#1A5CFF',
  SUCCESS: '#00C853',
  WARNING: '#FF9800',
  ERROR: '#F44336',
  TEXT_PRIMARY: '#333333',
  TEXT_SECONDARY: '#666666',
  TEXT_TERTIARY: '#999999',
  BORDER: '#E5E5E5',
  BACKGROUND: '#F5F5F5',
  WHITE: '#FFFFFF'
}

const Spacing: SpacingConfig = {
  SM: 8,
  MD: 12,
  LG: 16,
  XL: 20
}

@Entry
@Component
export struct CartPage {
  @State cartItems: CartItem[] = []
  @State totalPrice: number = 0
  @State selectedItems: Set<number> = new Set()

  private cartService: CartService = CartService.getInstance()

  aboutToAppear(): void {
    this.loadCart()
  }

  aboutToDisappear(): void {
    this.saveCart()
  }

  loadCart() {
    this.cartItems = this.cartService.getItems()
    this.totalPrice = this.cartService.getTotalPrice()
  }

  saveCart() {
    // 购物车数据已由 CartService 管理
  }

  getProductIcon(type: string): string {
    const icons: Record<string, string> = {
      'camera': '📷',
      'lock': '🔐',
      'sensor': '🌡️',
      'outlet': '🔌',
      'curtain': '🪟',
      'pir': '👁️',
      'air': '💨',
      'bulb': '💡',
      'door': '🚪',
      'speaker': '🔊'
    }
    return icons[type] || '📦'
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('🛒')
          .fontSize(24)

        Text('购物车')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .margin({ left: Spacing.SM })

        Blank()

        if (this.cartItems.length > 0) {
          Text('清空')
            .fontSize(14)
            .fontColor(Colors.ERROR)
            .onClick(() => {
              this.clearCart()
            })
        }
      }
      .width('100%')
      .padding(Spacing.LG)
      .backgroundColor(Colors.WHITE)

      if (this.cartItems.length === 0) {
        // 空购物车
        Column() {
          Text('🛒')
            .fontSize(80)
            .margin({ bottom: Spacing.XL })

          Text('购物车是空的')
            .fontSize(18)
            .fontColor(Colors.TEXT_SECONDARY)

          Text('快去挑选心仪的智能设备吧')
            .fontSize(14)
            .fontColor(Colors.TEXT_TERTIARY)
            .margin({ top: Spacing.SM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 购物车列表
        List() {
          ForEach(this.cartItems, (item: CartItem) => {
            ListItem() {
              this.CartItemCard(item)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Spacing.LG, right: Spacing.LG })
        .divider({ strokeWidth: 1, color: Colors.BORDER })
      }

      // 底部结算栏
      if (this.cartItems.length > 0) {
        Row() {
          // 总计
          Column() {
            Text('合计')
              .fontSize(14)
              .fontColor(Colors.TEXT_SECONDARY)

            Text('¥' + this.totalPrice.toFixed(2))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.ERROR)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 结算按钮
          Button('去结算')
            .fontSize(16)
            .fontColor(Colors.WHITE)
            .backgroundColor(Colors.BRAND)
            .borderRadius(24)
            .width(140)
            .height(48)
            .onClick(() => {
              this.checkout()
            })
        }
        .width('100%')
        .padding(Spacing.LG)
        .backgroundColor(Colors.WHITE)
        .shadow({
          radius: 8,
          color: '#20000000',
          offsetY: -2
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  @Builder
  CartItemCard(item: CartItem) {
    Row({ space: Spacing.MD }) {
      // 商品图标
      Text(this.getProductIcon(item.product.image))
        .fontSize(40)
        .padding(Spacing.MD)
        .backgroundColor(Colors.BACKGROUND)
        .borderRadius(12)

      // 商品信息
      Column({ space: 4 }) {
        Text(item.product.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.product.description)
          .fontSize(12)
          .fontColor(Colors.TEXT_TERTIARY)
          .maxLines(1)

        Row() {
          Text('¥' + item.product.price)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.ERROR)

          Blank()

          // 数量控制
          Row({ space: Spacing.SM }) {
            Text('-')
              .fontSize(18)
              .fontColor(Colors.TEXT_SECONDARY)
              .width(28)
              .height(28)
              .borderRadius(14)
              .backgroundColor(Colors.BACKGROUND)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.decreaseQuantity(item)
              })

            Text(item.quantity.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .width(32)
              .textAlign(TextAlign.Center)

            Text('+')
              .fontSize(18)
              .fontColor(Colors.TEXT_SECONDARY)
              .width(28)
              .height(28)
              .borderRadius(14)
              .backgroundColor(Colors.BACKGROUND)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.increaseQuantity(item)
              })
          }
        }
        .margin({ top: Spacing.SM })
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 删除按钮
      Text('🗑️')
        .fontSize(20)
        .padding(Spacing.SM)
        .onClick(() => {
          this.removeItem(item)
        })
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(Colors.WHITE)
    .borderRadius(12)
    .margin({ bottom: Spacing.MD })
  }

  increaseQuantity(item: CartItem) {
    this.cartService.updateQuantity(item.product.id, item.quantity + 1)
    this.loadCart()
  }

  decreaseQuantity(item: CartItem) {
    this.cartService.updateQuantity(item.product.id, item.quantity - 1)
    this.loadCart()
  }

  removeItem(item: CartItem) {
    this.cartService.removeFromCart(item.product.id)
    this.loadCart()
    prompt.showToast({ message: '已从购物车移除' })
  }

  clearCart() {
    this.cartService.clearCart()
    this.loadCart()
    prompt.showToast({ message: '购物车已清空' })
  }

  checkout() {
    prompt.showToast({ message: `结算 ¥${this.totalPrice.toFixed(2)}` })
  }
}