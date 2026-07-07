import prompt from '@ohos.promptAction'
import router from '@ohos.router'
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
  private cartService: CartService = CartService.getInstance()
  @State cartItems: CartItem[] = []
  @State selectedItems: Set<number> = new Set<number>()
  @State isAllSelected: boolean = false
  @State totalPrice: number = 0
  @State isLoggedIn: boolean = false

  aboutToAppear(): void {
    this.loadCartItems()
    // 模拟登录状态，实际项目中应从AppStorage或状态管理中获取
    this.isLoggedIn = false
  }

  // 加载购物车数据
  loadCartItems(): void {
    this.cartItems = this.cartService.getItems()
    this.calculateTotalPrice()
  }

  // 计算选中商品总价
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

  // 更新全选状态
  updateAllSelectedState(): void {
    if (this.cartItems.length === 0) {
      this.isAllSelected = false
      return
    }
    
    const allSelected = this.cartItems.every(item => this.selectedItems.has(item.product.id))
    this.isAllSelected = allSelected
  }

  // 切换单个商品选中状态
  toggleItemSelection(productId: number): void {
    if (this.selectedItems.has(productId)) {
      this.selectedItems.delete(productId)
    } else {
      this.selectedItems.add(productId)
    }
    this.calculateTotalPrice()
  }

  // 切换全选状态
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

  // 增加商品数量
  increaseQuantity(item: CartItem): void {
    if (item.quantity < item.product.stock) {
      this.cartService.updateQuantity(item.product.id, item.quantity + 1)
      this.loadCartItems()
    } else {
      prompt.showToast({ message: '已达到库存上限' })
    }
  }

  // 减少商品数量
  decreaseQuantity(item: CartItem): void {
    if (item.quantity > 1) {
      this.cartService.updateQuantity(item.product.id, item.quantity - 1)
      this.loadCartItems()
    } else {
      // 数量为1时减少会移除商品
      this.removeItem(item)
    }
  }

  // 移除商品
  removeItem(item: CartItem): void {
    this.cartService.removeItem(item.product.id)
    this.selectedItems.delete(item.product.id)
    this.loadCartItems()
    prompt.showToast({ message: '已移除商品' })
  }

  // 清空购物车
  clearCart(): void {
    this.cartService.clearCart()
    this.selectedItems.clear()
    this.loadCartItems()
    prompt.showToast({ message: '购物车已清空' })
  }

  // 结算
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
      // 这里可以跳转到登录页面
      return
    }
    
    // 检查库存
    if (!this.cartService.canCheckout()) {
      prompt.showToast({ message: '部分商品库存不足，请调整数量' })
      return
    }
    
    prompt.showToast({ message: `结算 ¥${this.totalPrice.toFixed(2)}` })
  }

  // 检查商品是否库存不足
  isOutOfStock(item: CartItem): boolean {
    return item.quantity > item.product.stock
  }

  // 获取商品图标
  getProductIcon(image: string): string {
    // 这里可以根据图片URL返回不同的图标
    // 暂时使用默认图标
    return '🛒'
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .margin({ left: Spacing.MD })
          .onClick(() => {
            router.back()
          })
        
        Text('购物车')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Text('清空')
          .fontSize(14)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ right: Spacing.MD })
          .onClick(() => {
            this.clearCart()
          })
      }
      .width('100%')
      .height(56)
      .backgroundColor(Colors.WHITE)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 购物车内容
      Column() {
        if (this.cartItems.length === 0) {
          // 空状态
          Column() {
            Text('🛒')
              .fontSize(80)
              .margin({ bottom: Spacing.LG })
            
            Text('购物车是空的')
              .fontSize(16)
              .fontColor(Colors.TEXT_SECONDARY)
              .margin({ bottom: Spacing.SM })
            
            Text('去挑选喜欢的商品吧')
              .fontSize(14)
              .fontColor(Colors.TEXT_TERTIARY)
              .margin({ bottom: Spacing.XL })
            
            Button('去逛逛')
              .fontSize(16)
              .fontColor(Colors.WHITE)
              .backgroundColor(Colors.BRAND)
              .borderRadius(24)
              .width(140)
              .height(48)
              .onClick(() => {
                router.back()
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
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

          // 底部结算栏
          Row() {
            // 全选
            Row({ space: Spacing.SM }) {
              Text(this.isAllSelected ? '☑️' : '⬜')
                .fontSize(20)
                .onClick(() => {
                  this.toggleAllSelection()
                })
              
              Text('全选')
                .fontSize(14)
                .fontColor(Colors.TEXT_SECONDARY)
            }
            .alignItems(VerticalAlign.Center)

            Blank()
              .layoutWeight(1)

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
              .layoutWeight(1)

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
    .width('100%')
    .height('100%')
  }

  @Builder
  CartItemCard(item: CartItem) {
    Row({ space: Spacing.MD }) {
      // 勾选框
      Text(this.selectedItems.has(item.product.id) ? '✅' : '⬜')
        .fontSize(20)
        .onClick(() => {
          this.toggleItemSelection(item.product.id)
        })

      // 商品图标
      Text(this.getProductIcon(item.product.image))
        .fontSize(40)
        .padding(Spacing.MD)
        .backgroundColor(Colors.BACKGROUND)
        .borderRadius(12)

      // 商品信息
      Column({ space: Spacing.SM }) {
        Text(item.product.name)
          .fontSize(16)
          .fontColor(Colors.TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(`¥${item.product.price.toFixed(2)}`)
          .fontSize(14)
          .fontColor(Colors.ERROR)
          .fontWeight(FontWeight.Bold)

        // 库存不足提示
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

      // 数量控制
      Row({ space: Spacing.SM }) {
        Button('-')
          .fontSize(16)
          .fontColor(Colors.TEXT_PRIMARY)
          .backgroundColor(Colors.BACKGROUND)
          .width(32)
          .height(32)
          .borderRadius(16)
          .onClick(() => {
            this.decreaseQuantity(item)
          })
        
        Text(item.quantity.toString())
          .fontSize(16)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(40)
          .textAlign(TextAlign.Center)
        
        Button('+')
          .fontSize(16)
          .fontColor(Colors.TEXT_PRIMARY)
          .backgroundColor(Colors.BACKGROUND)
          .width(32)
          .height(32)
          .borderRadius(16)
          .onClick(() => {
            this.increaseQuantity(item)
          })
      }
      .alignItems(VerticalAlign.Center)

      // 删除按钮
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
    .backgroundColor(Colors.WHITE)
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: '#10000000',
      offsetY: 1
    })
  }
}