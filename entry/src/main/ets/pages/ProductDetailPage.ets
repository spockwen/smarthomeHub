import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import { ProductService, Product } from '../service/ProductService'
import { CartService } from '../service/CartService'
import { ThemeColors, Spacing, FontSize, BorderRadius } from '../common/DesignConstants'

interface ReviewItem {
  userName: string
  rating: number
  content: string
  date: string
}

interface SpecItem {
  label: string
  value: string
}

@Entry
@Component
struct ProductDetailPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State product: Product | null = null
  @State quantity: number = 1
  @State isExpanded: boolean = false
  @State selectedTab: number = 0

  private productService: ProductService = ProductService.getInstance()
  private cartService: CartService = CartService.getInstance()

  private reviews: ReviewItem[] = []
  private specs: SpecItem[] = []

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, number>
    if (params && params['productId']) {
      const id = params['productId']
      this.product = this.productService.getProductById(id) || null
      if (this.product) {
        this.initSpecs(this.product)
        this.initReviews(this.product)
      }
    }
  }

  initSpecs(product: Product): void {
    const specMap: Record<string, SpecItem[]> = {
      'camera': [
        { label: '分辨率', value: '2K超清' },
        { label: '夜视距离', value: '10米' },
        { label: '视野角度', value: '130°广角' },
        { label: '存储方式', value: '云存储+本地SD卡' },
        { label: '连接方式', value: 'WiFi 2.4GHz' },
        { label: '供电方式', value: 'DC 5V/2A' }
      ],
      'lock': [
        { label: '开锁方式', value: '指纹+密码+钥匙+APP' },
        { label: '指纹容量', value: '200枚' },
        { label: '密码容量', value: '100组' },
        { label: '材质', value: 'C级锁芯+锌合金' },
        { label: '供电方式', value: '4节5号电池' },
        { label: '应急供电', value: 'Type-C接口' }
      ],
      'sensor': [
        { label: '温度精度', value: '±0.1°C' },
        { label: '湿度精度', value: '±2%RH' },
        { label: '测温范围', value: '-20~60°C' },
        { label: '测湿范围', value: '0~100%RH' },
        { label: '连接方式', value: 'Zigbee 3.0' },
        { label: '供电方式', value: 'CR2032纽扣电池' }
      ],
      'outlet': [
        { label: '额定功率', value: '2200W' },
        { label: '额定电流', value: '10A' },
        { label: '电压范围', value: 'AC 100-240V' },
        { label: '连接方式', value: 'WiFi 2.4GHz' },
        { label: '定时功能', value: '支持' },
        { label: '用电统计', value: '支持' }
      ],
      'curtain': [
        { label: '轨道类型', value: '直轨/弯轨' },
        { label: '最大承重', value: '50kg' },
        { label: '运行噪音', value: '≤35dB' },
        { label: '连接方式', value: 'Zigbee 3.0' },
        { label: '供电方式', value: 'AC 220V' },
        { label: '手拉启动', value: '支持' }
      ],
      'pir': [
        { label: '探测角度', value: '120°' },
        { label: '探测距离', value: '6米' },
        { label: '安装高度', value: '2.0~2.4米' },
        { label: '响应时间', value: '<0.5秒' },
        { label: '连接方式', value: 'Zigbee 3.0' },
        { label: '供电方式', value: 'CR2032纽扣电池' }
      ],
      'air': [
        { label: '检测项目', value: 'PM2.5/甲醛/温湿度' },
        { label: 'PM2.5范围', value: '0~500μg/m³' },
        { label: '甲醛范围', value: '0~2mg/m³' },
        { label: '显示方式', value: 'LCD数显' },
        { label: '连接方式', value: 'WiFi 2.4GHz' },
        { label: '供电方式', value: 'DC 5V/1A' }
      ],
      'bulb': [
        { label: '色温范围', value: '2700~6500K' },
        { label: '额定功率', value: '9W' },
        { label: '光通量', value: '800lm' },
        { label: '灯头规格', value: 'E27' },
        { label: '连接方式', value: 'WiFi 2.4GHz' },
        { label: '使用寿命', value: '25000小时' }
      ],
      'door': [
        { label: '感应距离', value: '15mm' },
        { label: '响应时间', value: '<1秒' },
        { label: '安装方式', value: '门框粘贴' },
        { label: '连接方式', value: 'Zigbee 3.0' },
        { label: '供电方式', value: 'CR1632纽扣电池' },
        { label: '电池寿命', value: '约2年' }
      ],
      'speaker': [
        { label: '扬声器', value: '全频3W' },
        { label: '麦克风', value: '2远场麦克风' },
        { label: '语音助手', value: '智能语音' },
        { label: '连接方式', value: 'WiFi 2.4GHz+蓝牙5.0' },
        { label: '供电方式', value: 'DC 5V/2A' },
        { label: '音频格式', value: 'MP3/AAC/FLAC' }
      ]
    }
    this.specs = specMap[product.image] || [
      { label: '品牌', value: 'SmartHome' },
      { label: '型号', value: product.name },
      { label: '连接方式', value: 'WiFi/Zigbee' },
      { label: '保修期', value: '1年' }
    ]
  }

  initReviews(product: Product): void {
    this.reviews = [
      { userName: '用***1', rating: 5, content: '非常好用，安装简单，反应灵敏，智能家居必备！', date: '2025-06-15' },
      { userName: '用***2', rating: 4, content: '产品质量不错，性价比很高，值得购买。', date: '2025-06-10' },
      { userName: '用***3', rating: 5, content: '第二次购买了，非常满意，推荐给朋友了。', date: '2025-05-28' },
      { userName: '用***4', rating: 4, content: '整体不错，APP操作方便，就是配送稍慢。', date: '2025-05-15' }
    ]
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

  getCategoryIcon(category: string): string {
    const icons: Record<string, string> = {
      '智能设备': '📱',
      '传感器': '📡',
      '控制器': '🎮',
      '安防设备': '🔒',
      '健康监测': '💗'
    }
    return icons[category] || '📦'
  }

  increaseQuantity(): void {
    if (this.product && this.quantity < this.product.stock) {
      this.quantity++
    } else {
      prompt.showToast({ message: '已达到库存上限' })
    }
  }

  decreaseQuantity(): void {
    if (this.quantity > 1) {
      this.quantity--
    }
  }

  addToCart(): void {
    if (!this.product) {
      return
    }
    const success = this.cartService.addToCart(this.product)
    if (success) {
      prompt.showToast({ message: '已添加到购物车' })
    } else {
      prompt.showToast({ message: '库存不足，无法添加' })
    }
  }

  buyNow(): void {
    if (!this.product) {
      return
    }
    this.cartService.addToCart(this.product)
    router.pushUrl({ url: 'pages/CartPage' })
  }

  goBack(): void {
    router.back()
  }

  getDiscount(): number {
    if (!this.product || this.product.originalPrice <= 0) {
      return 0
    }
    return Math.round((1 - this.product.price / this.product.originalPrice) * 100)
  }

  renderStars(rating: number): string {
    const full = Math.floor(rating)
    let stars = ''
    for (let i = 0; i < full; i++) {
      stars += '★'
    }
    for (let i = full; i < 5; i++) {
      stars += '☆'
    }
    return stars
  }

  @Builder
  HeaderBar() {
    Row() {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .fontWeight(500)
      }
      .width(40)
      .height(40)
      .borderRadius(BorderRadius.FULL)
      .backgroundColor(this.isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ left: Spacing.LG })
      .onClick(() => {
        this.goBack()
      })

      Text('商品详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row() {
        Text('🛒')
          .fontSize(20)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width(40)
      .height(40)
      .borderRadius(BorderRadius.FULL)
      .backgroundColor(this.isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ right: Spacing.LG })
      .onClick(() => {
        router.pushUrl({ url: 'pages/CartPage' })
      })
    }
    .width('100%')
    .height(56)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ProductHero() {
    Column() {
      Text(this.getProductIcon(this.product?.image || ''))
        .fontSize(80)
        .margin({ top: Spacing.XL, bottom: Spacing.XL })

      Row() {
        Text('¥' + (this.product?.price.toFixed(2) || '0.00'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF3B30')

        if (this.product && this.product.originalPrice > this.product.price) {
          Text('¥' + this.product.originalPrice.toFixed(2))
            .fontSize(14)
            .fontColor(ThemeColors.textTertiary(this.isDark))
            .decoration({ type: TextDecorationType.LineThrough })
            .margin({ left: Spacing.SM })

          Text('-' + this.getDiscount() + '%')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF3B30')
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .margin({ left: Spacing.SM })
        }
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ top: Spacing.LG, bottom: Spacing.LG })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder
  ProductInfo() {
    Column({ space: Spacing.MD }) {
      Text(this.product?.name || '')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary(this.isDark))

      Text(this.product?.description || '')
        .fontSize(14)
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .lineHeight(22)

      Row({ space: Spacing.LG }) {
        Row({ space: 4 }) {
          Text(this.renderStars(this.product?.rating || 0))
            .fontSize(14)
            .fontColor('#FFB800')
          Text((this.product?.rating.toFixed(1) || '0.0'))
            .fontSize(14)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }

        Text('已售' + (this.product?.sales || 0) + '件')
          .fontSize(14)
          .fontColor(ThemeColors.textSecondary(this.isDark))

        Text(this.getProductIcon(this.product?.category || '') + ' ' + (this.product?.category || ''))
          .fontSize(14)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }

      Row() {
        Text('库存: ' + (this.product?.stock || 0) + '件')
          .fontSize(13)
          .fontColor(this.product && this.product.stock > 0 ? ThemeColors.textTertiary(this.isDark) : '#FF3B30')
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .margin({ top: Spacing.SM })
  }

  @Builder
  QuantitySelector() {
    Row() {
      Text('数量')
        .fontSize(16)
        .fontColor(ThemeColors.textPrimary(this.isDark))

      Blank()

      Row({ space: 0 }) {
        Row() {
          Text('-')
            .fontSize(18)
            .fontColor(ThemeColors.textPrimary(this.isDark))
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ThemeColors.itemBg(this.isDark))
        .borderRadius({ topLeft: 8, bottomLeft: 8 })
        .onClick(() => {
          this.decreaseQuantity()
        })

        Text(this.quantity.toString())
          .fontSize(16)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .width(48)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(ThemeColors.itemBg(this.isDark))

        Row() {
          Text('+')
            .fontSize(18)
            .fontColor(ThemeColors.textPrimary(this.isDark))
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ThemeColors.itemBg(this.isDark))
        .borderRadius({ topRight: 8, bottomRight: 8 })
        .onClick(() => {
          this.increaseQuantity()
        })
      }
    }
    .width('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
    .backgroundColor(ThemeColors.surface(this.isDark))
    .margin({ top: Spacing.SM })
  }

  @Builder
  TabBar() {
    Row() {
      ForEach(['商品规格', '用户评价'], (tab: string, index: number) => {
        Column() {
          Text(tab)
            .fontSize(15)
            .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedTab === index ? '#1A5CFF' : ThemeColors.textSecondary(this.isDark))

          Row()
            .width(24)
            .height(3)
            .borderRadius(2)
            .backgroundColor(this.selectedTab === index ? '#1A5CFF' : 'transparent')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .padding({ top: Spacing.MD, bottom: Spacing.MD })
        .onClick(() => {
          this.selectedTab = index
        })
      })
    }
    .width('100%')
    .backgroundColor(ThemeColors.surface(this.isDark))
    .margin({ top: Spacing.SM })
  }

  @Builder
  SpecsContent() {
    Column({ space: 0 }) {
      ForEach(this.specs, (spec: SpecItem) => {
        Row() {
          Text(spec.label)
            .fontSize(14)
            .fontColor(ThemeColors.textSecondary(this.isDark))
            .width(80)

          Text(spec.value)
            .fontSize(14)
            .fontColor(ThemeColors.textPrimary(this.isDark))
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
        .borderRadius(0)
      })
    }
    .width('100%')
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder
  ReviewsContent() {
    Column({ space: Spacing.MD }) {
      if (this.reviews.length === 0) {
        Column() {
          Text('暂无评价')
            .fontSize(14)
            .fontColor(ThemeColors.textTertiary(this.isDark))
        }
        .width('100%')
        .padding(Spacing.XL)
        .alignItems(HorizontalAlign.Center)
      } else {
        ForEach(this.reviews, (review: ReviewItem) => {
          Row({ space: Spacing.MD }) {
            Row() {
              Text(review.userName.charAt(0))
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor('#1A5CFF')
            .justifyContent(FlexAlign.Center)

            Column({ space: 4 }) {
              Row() {
                Text(review.userName)
                  .fontSize(14)
                  .fontColor(ThemeColors.textPrimary(this.isDark))
                  .fontWeight(FontWeight.Medium)

                Blank()

                Text(review.date)
                  .fontSize(12)
                  .fontColor(ThemeColors.textTertiary(this.isDark))
              }
              .width('100%')

              Text(this.renderStars(review.rating))
                .fontSize(12)
                .fontColor('#FFB800')

              Text(review.content)
                .fontSize(14)
                .fontColor(ThemeColors.textSecondary(this.isDark))
                .lineHeight(20)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(Spacing.LG)
          .backgroundColor(ThemeColors.surface(this.isDark))
          .borderRadius(12)
        })
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(ThemeColors.bg(this.isDark))
  }

  @Builder
  BottomBar() {
    Row({ space: Spacing.MD }) {
      Row({ space: Spacing.XL }) {
        Column({ space: 2 }) {
          Text('客服')
            .fontSize(10)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ left: Spacing.MD, right: Spacing.MD })

        Column({ space: 2 }) {
          Text('🛒')
            .fontSize(20)
            .fontColor(ThemeColors.textPrimary(this.isDark))
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ left: Spacing.MD, right: Spacing.MD })
        .onClick(() => {
          router.pushUrl({ url: 'pages/CartPage' })
        })
      }

      Button('加入购物车')
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF9800')
        .borderRadius(24)
        .layoutWeight(1)
        .height(44)
        .onClick(() => {
          this.addToCart()
        })

      Button('立即购买')
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor('#1A5CFF')
        .borderRadius(24)
        .layoutWeight(1)
        .height(44)
        .onClick(() => {
          this.buyNow()
        })
    }
    .width('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({ radius: 8, color: ThemeColors.cardShadow(this.isDark), offsetY: -2 })
  }

  build() {
    Column() {
      this.HeaderBar()

      Scroll() {
        Column() {
          this.ProductHero()
          this.ProductInfo()
          this.QuantitySelector()
          this.TabBar()

          if (this.selectedTab === 0) {
            this.SpecsContent()
          } else {
            this.ReviewsContent()
          }
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(ThemeColors.bg(this.isDark))

      this.BottomBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
