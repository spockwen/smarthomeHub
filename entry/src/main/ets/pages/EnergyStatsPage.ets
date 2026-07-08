/**
 * 能耗统计页 - 用电趋势图 + 分类饼图
 * 基于 HarmonyOS Design 规范实现
 */
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig, ThemeColors } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'

type TimeRange = 'day' | 'week' | 'month'

interface EnergyDataPoint {
  time: string
  value: number
}

interface DeviceEnergy {
  id: string
  name: string
  icon: string
  energy: number
  percentage: number
}

interface CategoryItem {
  name: string
  value: number
  color: string
  percentage: number
}

interface TimeRangeOption {
  id: string
  name: string
}

@Entry
@Component
export struct EnergyStatsPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State private timeRange: TimeRange = 'day'
  @State private totalEnergy: number = 8.5
  @State private comparedPercentage: number = -12.3
  @State private trendData: EnergyDataPoint[] = [
    { time: '00:00', value: 0.2 },
    { time: '04:00', value: 0.1 },
    { time: '08:00', value: 0.8 },
    { time: '12:00', value: 1.2 },
    { time: '16:00', value: 1.5 },
    { time: '20:00', value: 2.3 },
    { time: '24:00', value: 2.4 }
  ]
  @State private categoryData: CategoryItem[] = [
    { name: '照明', value: 2.5, color: '#FFB800', percentage: 29 },
    { name: '空调', value: 4.2, color: '#007DFF', percentage: 49 },
    { name: '家电', value: 1.3, color: '#00C854', percentage: 15 },
    { name: '其他', value: 0.5, color: '#6B7280', percentage: 7 }
  ]
  @State private deviceRanking: DeviceEnergy[] = [
    { id: '1', name: '空调', icon: '❄️', energy: 4.2, percentage: 49 },
    { id: '2', name: '客厅灯', icon: '💡', energy: 1.5, percentage: 18 },
    { id: '3', name: '卧室灯', icon: '💡', energy: 0.8, percentage: 9 },
    { id: '4', name: '智能电视', icon: '📺', energy: 0.7, percentage: 8 },
    { id: '5', name: '智能插座', icon: '🔌', energy: 0.6, percentage: 7 }
  ]

  private readonly timeRanges: TimeRangeOption[] = [
    { id: 'day', name: '今日' },
    { id: 'week', name: '本周' },
    { id: 'month', name: '本月' }
  ]

  build() {
    Column() {
      this.NavigationBar()

      Scroll() {
        Column({ space: Spacing.LG }) {
          this.TotalEnergyCard()
          this.TrendChart()
          this.CategoryChart()
          this.DeviceRanking()
          this.EnergyTips()
        }
        .width('100%')
        .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }

  @Builder NavigationBar() {
    Row() {
      HaloButton({
        icon: '←',
        buttonSize: 'medium',
        type: 'ghost'
      })

      Blank()

      Text('能耗统计')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))

      Blank()

      HaloButton({
        icon: '📊',
        buttonSize: 'medium',
        type: 'ghost'
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder TotalEnergyCard() {
    Column({ space: Spacing.LG }) {
      Row({ space: Spacing.SM }) {
        ForEach(this.timeRanges, (range: TimeRangeOption) => {
          Text(range.name)
            .fontSize(FontSize.BODY2)
            .fontColor(this.timeRange === range.id ? Colors.BRAND_PRIMARY : ThemeColors.textSecondary(this.isDark))
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(BorderRadius.MEDIUM)
            .backgroundColor(this.timeRange === range.id ? ThemeColors.selectedBg(this.isDark) : 'transparent')
            .onClick(() => {
              this.timeRange = range.id as TimeRange
              if (range.id === 'week') {
                this.totalEnergy = 62.3
                this.comparedPercentage = -8.5
              } else if (range.id === 'month') {
                this.totalEnergy = 245.8
                this.comparedPercentage = -15.2
              } else {
                this.totalEnergy = 8.5
                this.comparedPercentage = -12.3
              }
            })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Column({ space: 8 }) {
        Row({ space: 4 }) {
          Text(this.totalEnergy.toFixed(1))
            .fontSize(48)
            .fontWeight(700)
            .fontColor(ThemeColors.textPrimary(this.isDark))

          Text('kWh')
            .fontSize(FontSize.TITLE3)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }

        Row({ space: 4 }) {
          Text(this.comparedPercentage < 0 ? '↓' : '↑')
            .fontSize(16)
            .fontColor(this.comparedPercentage < 0 ? Colors.SUCCESS : Colors.ERROR)

          Text(`${Math.abs(this.comparedPercentage).toFixed(1)}%`)
            .fontSize(FontSize.BODY2)
            .fontColor(this.comparedPercentage < 0 ? Colors.SUCCESS : Colors.ERROR)

          Text('同比昨日')
            .fontSize(FontSize.BODY2)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
      }
    }
    .width('100%')
    .padding(Spacing.XL)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: 4,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder TrendChart() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('📈')
          .fontSize(20)

        Text('用电趋势')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width('100%')

      Column() {
        Row({ space: 4 }) {
          ForEach(this.trendData, (point: EnergyDataPoint, index: number) => {
            Column({ space: 4 }) {
              Column()
                .width(20)
                .height(point.value * 40)
                .borderRadius({ topLeft: 4, topRight: 4 })
                .linearGradient({
                  angle: 180,
                  colors: [
                    [Colors.BRAND_PRIMARY, 0],
                    [Colors.BRAND_SECONDARY, 1]
                  ]
                })

              if (index % 2 === 0) {
                Text(point.time.split(':')[0] + 'h')
                  .fontSize(FontSize.CAPTION2)
                  .fontColor(ThemeColors.textTertiary(this.isDark))
              }
            }
            .height('100%')
            .justifyContent(FlexAlign.End)
          })
        }
        .width('100%')
        .height(120)
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .height(140)
      .padding(Spacing.MD)
      .borderRadius(BorderRadius.MEDIUM)
      .backgroundColor(ThemeColors.itemBg(this.isDark))
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder CategoryChart() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('📊')
          .fontSize(20)

        Text('分类能耗')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width('100%')

      Column({ space: Spacing.SM }) {
        ForEach(this.categoryData, (item: CategoryItem) => {
          Row() {
            Column()
              .width(12)
              .height(12)
              .borderRadius(6)
              .backgroundColor(item.color)

            Text(item.name)
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .margin({ left: Spacing.SM })

            Blank()

            Row({ space: 8 }) {
              Text(`${item.value}kWh`)
                .fontSize(FontSize.BODY2)
                .fontWeight(500)
                .fontColor(ThemeColors.textPrimary(this.isDark))

              Text(`${item.percentage}%`)
                .fontSize(FontSize.CAPTION1)
                .fontColor(ThemeColors.textSecondary(this.isDark))
            }
          }
          .width('100%')
          .padding(Spacing.SM)
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder DeviceRanking() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('🏆')
          .fontSize(20)

        Text('设备能耗排行')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width('100%')

      Column({ space: Spacing.SM }) {
        ForEach(this.deviceRanking, (device: DeviceEnergy, index: number) => {
          Row() {
            Text(`${index + 1}`)
              .fontSize(FontSize.BODY1)
              .fontWeight(600)
              .fontColor(index < 3 ? Colors.BRAND_PRIMARY : ThemeColors.textTertiary(this.isDark))
              .width(24)

            Text(device.icon)
              .fontSize(24)
              .margin({ left: Spacing.SM })

            Text(device.name)
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .margin({ left: Spacing.SM })
              .layoutWeight(1)

            Text(`${device.energy}kWh`)
              .fontSize(FontSize.BODY2)
              .fontWeight(500)
              .fontColor(ThemeColors.textPrimary(this.isDark))
          }
          .width('100%')
          .padding(Spacing.SM)
          .borderRadius(BorderRadius.MEDIUM)
          .backgroundColor(ThemeColors.itemBg(this.isDark))
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder EnergyTips() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('💡')
          .fontSize(20)

        Text('节能建议')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width('100%')

      Column({ space: Spacing.SM }) {
        this.TipItem('空调温度设置在26℃可节省约10%能耗', '❄️')
        this.TipItem('离开房间时记得关闭灯光', '💡')
        this.TipItem('使用定时功能自动关闭设备', '⏰')
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder TipItem(text: string, icon: string) {
    Row({ space: Spacing.SM }) {
      Text(icon)
        .fontSize(20)

      Text(text)
        .fontSize(FontSize.BODY2)
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.SM)
  }
}
