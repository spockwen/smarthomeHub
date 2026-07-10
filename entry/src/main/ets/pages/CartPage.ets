import prompt from '@ohos.promptAction'
import router from '@ohos.router'
import { CartService } from '../service/CartService'
import { CartItem } from '../service/ProductService'
import { ThemeColors } from '../common/DesignConstants'

interface ColorConfig {
  BRAND: string
  SUCCESS: string
  WARNING: string
  ERROR: string
  BORDER: string
}

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
  BORDER: '#E5E5E5'
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
  @StorageProp('isDarkMode') isDark: boolean = false
  private cartService: CartService = CartService.getInstance()
  @State cartItems: CartItem[] = []
  @State selectedItems: Set<number> = new Set<number>()
  @State isAllSelected: boolean = false
  @State totalPrice: number = 0
  @State isLoggedIn: boolean = false

  aboutToAppear(): void {
    this.loadCartItems()
    this.isLoggedIn = false
  }

  loadCartItems(): void {
    this.cartItems = this.cartService.getItems()
    this.calculateTotalPrice()
  }

  calculateTotalPrice(): void {
    let total = 0
    for (const item of this.cartItems) {
      if (this.selectedItems.has(item.product.id)) {
        total += item.product.price * item.quantity
      }
    }
    this.totalPrice = total
    this.updateAllSelectedState()
  }

  updateAllSelectedState(): void {
    if (this.cartItems.length === 0) {
      this.isAllSelected = false
      return
    }
    
    const allSelected = this.cartItems.every(item => this.selectedItems.has(item.product.id))
    this.isAllSelected = allSelected
  }

  toggleItemSelection(productId: number): void {
    if (this.selectedItems.has(productId)) {
      this.selectedItems.delete(productId)
    } else {
      this.selectedItems.add(productId)
    }
    this.calculateTotalPrice()
  }

  toggleAllSelection(): void {
    if (this.isAllSelected) {
      this.selectedItems.clear()
    } else {
      this.cartItems.forEach(item => {
        this.selectedItems.add(item.product.id)
      })
    }
    this.isAllSelected = !this.isAllSelected
    this.calculateTotalPrice()
  }

  increaseQuantity(item: CartItem): void {
    if (item.quantity < item.product.stock) {
      this.cartService.updateQuantity(item.product.id, item.quantity + 1)
      this.loadCartItems()
    } else {
      prompt.showToast({ message: '已达到库存上限' })
    }
  }

  decreaseQuantity(item: CartItem): void {
    if (item.quantity > 1) {
      this.cartService.updateQuantity(item.product.id, item.quantity - 1)
      this.loadCartItems()
    } else {
      this.removeItem(item)
    }
  }

  removeItem(item: CartItem): void {
    this.cartService.removeItem(item.product.id)
    this.selectedItems.delete(item.product.id)
    this.loadCartItems()
    prompt.showToast({ message: '已移除商品' })
  }

  clearCart(): void {
    this.cartService.clearCart()
    this.selectedItems.clear()
    this.loadCartItems()
    prompt.showToast({ message: '购物车已清空' })
  }

  checkout(): void {
    if (this.cartItems.length === 0) {
      prompt.showToast({ message: '购物车为空' })
      return
    }
    
    if (this.selectedItems.size === 0) {
      prompt.showToast({ message: '请选择要结算的商品' })
      return
    }
    
    if (!this.isLoggedIn) {
      prompt.showToast({ message: '请先登录' })
      return
    }
    
    if (!this.cartService.canCheckout()) {
      prompt.showToast({ message: '部分商品库存不足，请调整数量' })
      return
    }
    
    prompt.showToast({ message: `结算 ¥${this.totalPrice.toFixed(2)}` })
  }

  isOutOfStock(item: CartItem): boolean {
    return item.quantity > item.product.stock
  }

  getProductIcon(image: string): string {
    return '🛒'
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .margin({ left: Spacing.MD })
          .onClick(() => {
            router.back()
          })
        
        Text('购物车')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Text('清空')
          .fontSize(14)
          .fontColor(ThemeColors.textSecondary(this.isDark))
          .margin({ right: Spacing.MD })
          .onClick(() => {
            this.clearCart()
          })
      }
      .width('100%')
      .height(56)
      .backgroundColor(ThemeColors.surface(this.isDark))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column() {
        if (this.cartItems.length === 0) {
          Column() {
            Text('🛒')
              .fontSize(80)
              .margin({ bottom: Spacing.LG })
            
            Text('购物车是空的')
              .fontSize(16)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .margin({ bottom: Spacing.SM })
            
            Text('去挑选喜欢的商品吧')
              .fontSize(14)
              .fontColor(ThemeColors.textTertiary(this.isDark))
              .margin({ bottom: Spacing.XL })
            
            Button('去逛逛')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor(Colors.BRAND)
              .borderRadius(24)
              .width(140)
              .height(48)
              .onClick(() => {
                router.back()
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
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
          .divider({ strokeWidth: 1, color: this.isDark ? '#3A3A3A' : Colors.BORDER })

          Row() {
            Row({ space: Spacing.SM }) {
              Text(this.isAllSelected ? '☑️' : '⬜')
                .fontSize(20)
                .onClick(() => {
                  this.toggleAllSelection()
                })
              
              Text('全选')
                .fontSize(14)
                .fontColor(ThemeColors.textSecondary(this.isDark))
            }
            .alignItems(VerticalAlign.Center)

            Column() {
              Text('合计')
                .fontSize(14)
                .fontColor(ThemeColors.textSecondary(this.isDark))

              Text('¥' + this.totalPrice.toFixed(2))
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.ERROR)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: Spacing.LG })

            Button('去结算')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor(Colors.BRAND)
              .borderRadius(24)
              .width(140)
              .height(48)
              .onClick(() => {
                this.checkout()
              })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
          .backgroundColor(ThemeColors.surface(this.isDark))
          .shadow({
            radius: 8,
            color: ThemeColors.cardShadow(this.isDark),
            offsetY: -2
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(ThemeColors.bg(this.isDark))
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CartItemCard(item: CartItem) {
    Row({ space: Spacing.MD }) {
      Text(this.selectedItems.has(item.product.id) ? '✅' : '⬜')
        .fontSize(20)
        .onClick(() => {
          this.toggleItemSelection(item.product.id)
        })

      Text(this.getProductIcon(item.product.image))
        .fontSize(40)
        .padding(Spacing.MD)
        .backgroundColor(ThemeColors.itemBg(this.isDark))
        .borderRadius(12)

      Column({ space: Spacing.SM }) {
        Text(item.product.name)
          .fontSize(16)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(`¥${item.product.price.toFixed(2)}`)
          .fontSize(14)
          .fontColor(Colors.ERROR)
          .fontWeight(FontWeight.Bold)

        if (this.isOutOfStock(item)) {
          Text('库存不足')
            .fontSize(12)
            .fontColor(Colors.ERROR)
            .backgroundColor('#FFE5E5')
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(4)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row({ space: Spacing.SM }) {
        Button('-')
          .fontSize(16)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .backgroundColor(ThemeColors.itemBg(this.isDark))
          .width(32)
          .height(32)
          .borderRadius(16)
          .onClick(() => {
            this.decreaseQuantity(item)
          })
        
        Text(item.quantity.toString())
          .fontSize(16)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .width(40)
          .textAlign(TextAlign.Center)
        
        Button('+')
          .fontSize(16)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .backgroundColor(ThemeColors.itemBg(this.isDark))
          .width(32)
          .height(32)
          .borderRadius(16)
          .onClick(() => {
            this.increaseQuantity(item)
          })
      }
      .alignItems(VerticalAlign.Center)

      Button('删除')
        .fontSize(12)
        .fontColor(Colors.ERROR)
        .backgroundColor('#FFE5E5')
        .borderRadius(12)
        .padding({ left: Spacing.MD, right: Spacing.MD })
        .height(24)
        .onClick(() => {
          this.removeItem(item)
        })
    }
    .width('100%')
    .padding({ top: Spacing.MD, bottom: Spacing.MD })
    .backgroundColor(ThemeColors.surface(this.isDark))
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: ThemeColors.cardShadow(this.isDark),
      offsetY: 1
    })
  }
}
