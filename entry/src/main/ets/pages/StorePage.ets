// 商城首页 - 符合 ArkTS 规范
import prompt from '@ohos.promptAction'
import router from '@ohos.router'
import { ProductService, Product } from '../service/ProductService'
import { CartService } from '../service/CartService'
import { ThemeColors } from '../common/DesignConstants'

interface ColorConfig {
  BRAND: string
  SUCCESS: string
  WARNING: string
  ERROR: string
  BORDER: string
}

interface SpacingConfig {
  XS: number
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
  XS: 4,
  SM: 8,
  MD: 12,
  LG: 16,
  XL: 20
}

@Entry
@Component
export struct StorePage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State searchText: string = ''
  @State selectedCategory: string = '全部'
  @State products: Product[] = []
  @State cartCount: number = 0
  @State showCategorySheet: boolean = false

  private productService: ProductService = ProductService.getInstance()
  private cartService: CartService = CartService.getInstance()
  private categories: string[] = ['全部', '智能设备', '传感器', '控制器', '安防设备', '健康监测']

  aboutToAppear() {
    this.loadProducts()
    this.updateCartCount()
  }

  aboutToDisappear(): void {
    this.updateCartCount()
  }

  loadProducts() {
    if (this.selectedCategory === '全部') {
      this.products = this.productService.products
    } else {
      this.products = this.productService.getProductsByCategory(this.selectedCategory)
    }
  }

  updateCartCount() {
    this.cartCount = this.cartService.getCount()
  }

  getCategoryIcon(category: string): string {
    switch (category) {
      case '智能设备':
        return '📱'
      case '传感器':
        return '📡'
      case '控制器':
        return '🎮'
      case '安防设备':
        return '🔒'
      case '健康监测':
        return '💗'
      default:
        return '📦'
    }
  }

  build() {
    Column() {
      this.SearchBar()
      this.CategoryNav()
      this.ProductGrid()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }

  @Builder
  SearchBar() {
    Row({ space: Spacing.MD }) {
      Search({ placeholder: '搜索智能设备', value: this.searchText })
        .placeholderColor(ThemeColors.textTertiary(this.isDark))
        .backgroundColor(ThemeColors.surface(this.isDark))
        .borderRadius(20)
        .height(40)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.searchText = value
          if (value.trim()) {
            this.products = this.productService.searchProducts(value)
          } else {
            this.loadProducts()
          }
        })

      Badge({ count: this.cartCount, style: { fontSize: 10 } }) {
        Stack() {
          Text('🛒')
            .fontSize(24)
        }
        .width(40)
        .height(40)
        .backgroundColor(ThemeColors.surface(this.isDark))
        .borderRadius(20)
      }
      .onClick(() => {
        router.pushUrl({ url: 'pages/CartPage' })
      })
    }
    .width('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.MD })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder
  CategoryNav() {
    Scroll() {
      Row({ space: Spacing.SM }) {
        ForEach(this.categories, (category: string) => {
          Text(category)
            .fontSize(14)
            .fontColor(this.selectedCategory === category ? '#FFFFFF' : ThemeColors.textPrimary(this.isDark))
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(this.selectedCategory === category ? Colors.BRAND : ThemeColors.surface(this.isDark))
            .borderRadius(20)
            .onClick(() => {
              this.selectedCategory = category
              this.loadProducts()
            })
        })
      }
      .padding({ left: Spacing.LG, right: Spacing.LG })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: Spacing.MD, bottom: Spacing.MD })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder
  ProductGrid() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        if (this.selectedCategory === '全部') {
          Row() {
            Text('🔥')
              .fontSize(20)
            Text('热门推荐')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .margin({ left: Spacing.SM })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG })

          this.HotProductsScroll()
        }

        Text('全部商品')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .alignSelf(ItemAlign.Start)
          .padding({ left: Spacing.LG })

        Grid() {
          ForEach(this.products, (product: Product) => {
            GridItem() {
              this.ProductCard(product)
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .padding({ left: Spacing.LG, right: Spacing.LG })
        .width('100%')
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  HotProductsScroll() {
    Scroll() {
      Row({ space: Spacing.MD }) {
        ForEach(this.productService.getHotProducts(), (product: Product) => {
          Column() {
            Text(this.getProductIcon(product.image))
              .fontSize(40)
              .padding(16)

            Text(product.name)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('¥' + product.price)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.ERROR)
          }
          .width(120)
          .padding(Spacing.MD)
          .backgroundColor(ThemeColors.surface(this.isDark))
          .borderRadius(12)
          .onClick(() => {
            this.showProductDetail(product)
          })
        })
      }
      .padding({ left: Spacing.LG, right: Spacing.LG })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .margin({ top: Spacing.MD })
  }

  @Builder
  ProductCard(product: Product) {
    Column() {
      Text(this.getProductIcon(product.image))
        .fontSize(36)
        .padding(Spacing.LG)

      Text(product.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(product.description)
        .fontSize(12)
        .fontColor(ThemeColors.textTertiary(this.isDark))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 2 })

      Row() {
        Column() {
          Text('¥' + product.price)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.ERROR)

          if (product.originalPrice > product.price) {
            Text('¥' + product.originalPrice)
              .fontSize(10)
              .fontColor(ThemeColors.textTertiary(this.isDark))
              .decoration({ type: TextDecorationType.LineThrough })
          }
        }

        Text('🛒')
          .fontSize(20)
          .padding(8)
          .backgroundColor(Colors.BRAND)
          .borderRadius(16)
          .onClick(() => {
            this.addToCart(product)
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .borderRadius(12)
    .onClick(() => {
      this.showProductDetail(product)
    })
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

  addToCart(product: Product) {
    const success = this.cartService.addToCart(product)
    if (success) {
      this.updateCartCount()
      prompt.showToast({ message: '已添加到购物车' })
    } else {
      prompt.showToast({ message: '库存不足，无法添加' })
    }
  }

  showProductDetail(product: Product) {
    prompt.showToast({ message: `查看 ${product.name} 详情` })
  }
}
