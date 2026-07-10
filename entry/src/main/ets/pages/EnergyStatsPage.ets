import router from '@ohos.router'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'

interface EnergyRecord {
  label: string
  value: number
  unit: string
  change: number
}

interface DeviceEnergy {
  name: string
  icon: string
  usage: number
  percentage: number
}

@Entry
@Component
struct EnergyStatsPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @StorageLink('powerUsage') powerUsage: number = 8.5
  @State selectedPeriod: string = '日'

  private periods: string[] = ['日', '周', '月', '年']

  private summaryData: EnergyRecord[] = [
    { label: '今日能耗', value: 8.5, unit: 'kWh', change: -12 },
    { label: '本周能耗', value: 62.3, unit: 'kWh', change: -8 },
    { label: '本月能耗', value: 245.8, unit: 'kWh', change: 5 },
    { label: '预计月费', value: 147.5, unit: '元', change: -3 }
  ]

  private deviceEnergyList: DeviceEnergy[] = [
    { name: '空调', icon: '❄️', usage: 3.2, percentage: 38 },
    { name: '热水器', icon: '♨️', usage: 2.1, percentage: 25 },
    { name: '电视', icon: '📺', usage: 1.0, percentage: 12 },
    { name: '取暖器', icon: '🔥', usage: 0.8, percentage: 9 },
    { name: '空气净化器', icon: '💨', usage: 0.5, percentage: 6 },
    { name: '智能灯泡', icon: '💡', usage: 0.3, percentage: 4 },
    { name: '其他设备', icon: '🔌', usage: 0.6, percentage: 6 }
  ]

  private hourlyData: number[] = [0.2, 0.1, 0.1, 0.1, 0.1, 0.2, 0.5, 0.8, 0.6, 0.4, 0.3, 0.5, 0.7, 0.4, 0.3, 0.5, 0.8, 1.2, 0.9, 0.6, 0.4, 0.3, 0.2, 0.1]

  build() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            router.back()
          })

        Text('能耗统计')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('  ')
          .fontSize(FontSize.BODY2)
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.LG, right: Spacing.LG })
      .backgroundColor(ThemeColors.surface(this.isDark))

      Scroll() {
        Column({ space: Spacing.LG }) {
          Row({ space: Spacing.SM }) {
            ForEach(this.periods, (period: string) => {
              Text(period)
                .fontSize(FontSize.CAPTION1)
                .fontColor(this.selectedPeriod === period ? '#FFFFFF' : ThemeColors.textSecondary(this.isDark))
                .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                .backgroundColor(this.selectedPeriod === period ? Colors.BRAND_PRIMARY : ThemeColors.surface(this.isDark))
                .borderRadius(16)
                .onClick(() => {
                  this.selectedPeriod = period
                })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: Spacing.MD })

          Row({ space: Spacing.SM }) {
            ForEach(this.summaryData, (record: EnergyRecord) => {
              Column({ space: 6 }) {
                Text(record.label)
                  .fontSize(FontSize.CAPTION1)
                  .fontColor(ThemeColors.textSecondary(this.isDark))

                Row({ space: 2 }) {
                  Text(record.value.toFixed(1))
                    .fontSize(FontSize.TITLE3)
                    .fontWeight(700)
                    .fontColor(ThemeColors.textPrimary(this.isDark))
                  Text(record.unit)
                    .fontSize(FontSize.CAPTION2)
                    .fontColor(ThemeColors.textTertiary(this.isDark))
                }

                Text((record.change > 0 ? '+' : '') + record.change + '%')
                  .fontSize(FontSize.CAPTION2)
                  .fontColor(record.change <= 0 ? Colors.SUCCESS : Colors.ERROR)
              }
              .layoutWeight(1)
              .padding(Spacing.MD)
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(ThemeColors.surface(this.isDark))
            })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG })

          Column({ space: Spacing.MD }) {
            Text('24小时能耗趋势')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: 0 }) {
              ForEach(this.hourlyData, (value: number, index: number) => {
                Row() {
                  Text((index < 10 ? '0' : '') + index + ':00')
                    .fontSize(10)
                    .fontColor(ThemeColors.textTertiary(this.isDark))
                    .width(40)

                  Row()
                    .height(12)
                    .borderRadius(6)
                    .width((value / 1.2 * 100).toString() + '%')
                    .backgroundColor(Colors.BRAND_PRIMARY)
                    .opacity(0.4 + value / 1.2 * 0.6)

                  Text(value.toFixed(1))
                    .fontSize(10)
                    .fontColor(ThemeColors.textTertiary(this.isDark))
                    .margin({ left: Spacing.XS })
                }
                .width('100%')
                .padding({ left: Spacing.LG, right: Spacing.LG, top: 3, bottom: 3 })
              })
            }
            .width('100%')
            .borderRadius(BorderRadius.LARGE)
            .backgroundColor(ThemeColors.surface(this.isDark))
            .padding({ top: Spacing.SM, bottom: Spacing.SM })
          }

          Column({ space: Spacing.MD }) {
            Text('设备能耗排行')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: Spacing.SM }) {
              ForEach(this.deviceEnergyList, (device: DeviceEnergy) => {
                Row() {
                  Text(device.icon)
                    .fontSize(24)
                    .margin({ right: Spacing.MD })

                  Column({ space: 4 }) {
                    Row() {
                      Text(device.name)
                        .fontSize(FontSize.BODY2)
                        .fontColor(ThemeColors.textPrimary(this.isDark))

                      Blank()

                      Text(device.usage.toFixed(1) + ' kWh')
                        .fontSize(FontSize.CAPTION1)
                        .fontColor(ThemeColors.textSecondary(this.isDark))
                    }
                    .width('100%')

                    Row() {
                      Row()
                        .height(6)
                        .borderRadius(3)
                        .width(device.percentage + '%')
                        .backgroundColor(Colors.BRAND_PRIMARY)
                        .opacity(0.7)

                      Blank()
                    }
                    .width('100%')
                    .backgroundColor(ThemeColors.itemBg(this.isDark))
                    .borderRadius(3)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .padding(Spacing.LG)
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(ThemeColors.surface(this.isDark))
              })
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Row() {
            Text('💡 提示：空调和热水器是主要耗电设备，合理设置温度可节省15%-30%能耗')
              .fontSize(FontSize.CAPTION1)
              .fontColor(ThemeColors.textTertiary(this.isDark))
              .lineHeight(18)
          }
          .width('100%')
          .padding(Spacing.LG)
          .borderRadius(BorderRadius.MEDIUM)
          .backgroundColor(ThemeColors.selectedBg(this.isDark))
        }
        .width('100%')
        .padding({ top: Spacing.SM, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
