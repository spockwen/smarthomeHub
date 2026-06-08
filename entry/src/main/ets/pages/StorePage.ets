// 商城首页 - 符合 ArkTS 规范
import prompt from '@ohos.promptAction'
import { ProductService, Product } from '../service/ProductService'
import { CartService } from '../service/CartService'

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
  TEXT_PRIMARY: '#333333',
  TEXT_SECONDARY: '#666666',
  TEXT_TERTIARY: '#999999',
  BORDER: '#E5E5E5',
  BACKGROUND: '#F5F5F5',
  WHITE: '#FFFFFF'
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
      // 顶部搜索栏
      this.SearchBar()

      // 分类导航
      this.CategoryNav()

      // 商品列表
      this.ProductGrid()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  @Builder
  SearchBar() {
    Row({ space: Spacing.MD }) {
      // 搜索框
      Search({ placeholder: '搜索智能设备', value: this.searchText })
        .placeholderColor(Colors.TEXT_TERTIARY)
        .backgroundColor(Colors.WHITE)
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

      // 购物车按钮
      Badge({ count: this.cartCount, style: { fontSize: 10 } }) {
        Stack() {
          Text('🛒')
            .fontSize(24)
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.WHITE)
        .borderRadius(20)
      }
      .onClick(() => {
        prompt.showToast({ message: '购物车功能开发中' })
      })
    }
    .width('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.MD })
    .backgroundColor(Colors.WHITE)
  }

  @Builder
  CategoryNav() {
    Scroll() {
      Row({ space: Spacing.SM }) {
        ForEach(this.categories, (category: string) => {
          Text(category)
            .fontSize(14)
            .fontColor(this.selectedCategory === category ? Colors.WHITE : Colors.TEXT_PRIMARY)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(this.selectedCategory === category ? Colors.BRAND : Colors.WHITE)
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
    .backgroundColor(Colors.WHITE)
  }

  @Builder
  ProductGrid() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        // 热门推荐标题
        if (this.selectedCategory === '全部') {
          Row() {
            Text('🔥')
              .fontSize(20)
            Text('热门推荐')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
              .margin({ left: Spacing.SM })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG })

          // 热门商品横向滚动
          this.HotProductsScroll()
        }

        // 商品网格
        Text('全部商品')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
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
            // 商品图标
            Text(this.getProductIcon(product.image))
              .fontSize(40)
              .padding(16)

            // 商品名称
            Text(product.name)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            // 价格
            Text('¥' + product.price)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.ERROR)
          }
          .width(120)
          .padding(Spacing.MD)
          .backgroundColor(Colors.WHITE)
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
      // 商品图标
      Text(this.getProductIcon(product.image))
        .fontSize(36)
        .padding(Spacing.LG)

      // 商品名称
      Text(product.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 描述
      Text(product.description)
        .fontSize(12)
        .fontColor(Colors.TEXT_TERTIARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 2 })

      // 价格和按钮
      Row() {
        Column() {
          Text('¥' + product.price)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.ERROR)

          if (product.originalPrice > product.price) {
            Text('¥' + product.originalPrice)
              .fontSize(10)
              .fontColor(Colors.TEXT_TERTIARY)
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
    .backgroundColor(Colors.WHITE)
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
    this.cartService.addToCart(product)
    this.updateCartCount()
    prompt.showToast({ message: '已添加到购物车' })
  }

  showProductDetail(product: Product) {
    prompt.showToast({ message: `查看 ${product.name} 详情` })
  }
}