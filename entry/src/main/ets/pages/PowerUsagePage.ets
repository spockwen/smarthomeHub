/**
 * 能耗详情页 - 今日能耗统计与分析
 * 展示能耗趋势、设备能耗排行、节能建议
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import router from '@ohos.router'

@Entry
@Component
struct PowerUsagePage {
  @StorageLink('powerUsage') powerUsage: number = 8.5
  @StorageProp('isDarkMode') isDark: boolean = false
  
  @State private powerHistory: number[] = [7.2, 8.1, 7.8, 8.5, 9.2, 8.8, 8.5]
  @State private devicePowerRank: DevicePowerInfo[] = [
    { name: '空调', icon: '❄️', power: 3.2, percentage: 38 },
    { name: '热水器', icon: '🚿', power: 2.1, percentage: 25 },
    { name: '电视', icon: '📺', power: 1.5, percentage: 18 },
    { name: '照明', icon: '💡', power: 0.8, percentage: 9 },
    { name: '其他', icon: '🔌', power: 0.9, percentage: 10 }
  ]
  
  build() {
    Column() {
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          this.TodayPowerCard()
          this.PowerTrendCard()
          this.DeviceRankCard()
          this.EnergySavingCard()
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
      Text('←')
        .fontSize(24)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .onClick(() => {
          router.back()
        })
      
      Text('今日能耗')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .margin({ left: Spacing.MD })
      
      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder TodayPowerCard() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text('⚡')
          .fontSize(40)
        
        Column({ space: 4 }) {
          Text(`${this.powerUsage} kWh`)
            .fontSize(48)
            .fontWeight(700)
            .fontColor(Colors.WARNING)
          
          Text('今日总能耗')
            .fontSize(FontSize.BODY2)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.LG })
        
        Blank()
        
        Column({ space: 4 }) {
          Text(this.getPowerStatus())
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor(this.getPowerStatusColor())
          
          Text(`${this.getPowerComparison()} 昨日`)
            .fontSize(FontSize.CAPTION1)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      
      Row() {
        Text('预估费用')
          .fontSize(FontSize.BODY2)
          .fontColor(ThemeColors.textSecondary(this.isDark))
        
        Blank()
        
        Text(`¥${(this.powerUsage * 0.6).toFixed(2)}`)
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.WARNING)
      }
      .width('100%')
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: 8,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 2
    })
  }
  
  @Builder PowerTrendCard() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('能耗趋势')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
        
        Blank()
        
        Text('近7天')
          .fontSize(FontSize.CAPTION1)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }
      .width('100%')
      
      Row({ space: 8 }) {
        ForEach(this.powerHistory, (power: number, index: number) => {
          Column({ space: 4 }) {
            Column()
              .width(32)
              .height(this.getBarHeight(power))
              .borderRadius(4)
              .backgroundColor(power >= 9 ? Colors.WARNING : 
                             power <= 7 ? Colors.SUCCESS : 
                             Colors.BRAND_PRIMARY)
            
            Text(this.getDayLabel(index))
              .fontSize(FontSize.CAPTION2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
          }
          .height(120)
          .justifyContent(FlexAlign.End)
        })
      }
      .width('100%')
      
      Row({ space: Spacing.LG }) {
        this.LegendItem('高耗能', Colors.WARNING)
        this.LegendItem('正常', Colors.BRAND_PRIMARY)
        this.LegendItem('节能', Colors.SUCCESS)
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder LegendItem(label: string, color: string) {
    Row({ space: 4 }) {
      Column()
        .width(12)
        .height(12)
        .borderRadius(2)
        .backgroundColor(color)
      
      Text(label)
        .fontSize(FontSize.CAPTION2)
        .fontColor(ThemeColors.textSecondary(this.isDark))
    }
  }
  
  @Builder DeviceRankCard() {
    Column({ space: Spacing.MD }) {
      Text('设备能耗排行')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
      ForEach(this.devicePowerRank, (device: DevicePowerInfo, index: number) => {
        this.DevicePowerItem(device, index)
      })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder DevicePowerItem(device: DevicePowerInfo, index: number) {
    Column({ space: 8 }) {
      Row() {
        Text(device.icon)
          .fontSize(24)
        
        Text(device.name)
          .fontSize(FontSize.BODY1)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .margin({ left: Spacing.SM })
        
        Blank()
        
        Text(`${device.power} kWh`)
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width('100%')
      
      Row() {
        Column()
          .width(`${device.percentage}%`)
          .height(6)
          .borderRadius(3)
          .backgroundColor(this.getPowerColor(device.power))
      }
      .width('100%')
      .height(6)
      .borderRadius(3)
      .backgroundColor(ThemeColors.bg(this.isDark))
    }
    .width('100%')
  }
  
  @Builder EnergySavingCard() {
    Column({ space: Spacing.MD }) {
      Text('节能建议')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
      Column({ space: Spacing.SM }) {
        this.AdviceItem('❄️', '空调温度设置26℃最节能')
        this.AdviceItem('💡', '使用LED灯泡可节省80%照明能耗')
        this.AdviceItem('🔌', '及时关闭待机设备，避免待机能耗')
        this.AdviceItem('🌡️', '定期清洁空调滤网，提高能效')
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder AdviceItem(icon: string, text: string) {
    Row({ space: Spacing.SM }) {
      Text(icon)
        .fontSize(20)
      
      Text(text)
        .fontSize(FontSize.BODY2)
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .layoutWeight(1)
    }
    .width('100%')
  }
  
  private getPowerStatus(): string {
    if (this.powerUsage >= 10) return '高耗能'
    if (this.powerUsage <= 7) return '节能'
    return '正常'
  }
  
  private getPowerStatusColor(): string {
    if (this.powerUsage >= 10) return Colors.WARNING
    if (this.powerUsage <= 7) return Colors.SUCCESS
    return Colors.BRAND_PRIMARY
  }
  
  private getPowerComparison(): string {
    const yesterday = this.powerHistory[this.powerHistory.length - 2]
    const diff = this.powerUsage - yesterday
    if (diff > 0) return `+${diff.toFixed(1)} kWh`
    if (diff < 0) return `${diff.toFixed(1)} kWh`
    return '持平'
  }
  
  private getBarHeight(power: number): number {
    const minPower = 5
    const maxPower = 12
    const minHeight = 20
    const maxHeight = 100
    const ratio = (power - minPower) / (maxPower - minPower)
    return minHeight + ratio * (maxHeight - minHeight)
  }
  
  private getDayLabel(index: number): string {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
    return days[index]
  }
  
  private getPowerColor(power: number): string {
    if (power >= 2) return Colors.WARNING
    if (power >= 1) return Colors.BRAND_PRIMARY
    return Colors.SUCCESS
  }
}

interface DevicePowerInfo {
  name: string
  icon: string
  power: number
  percentage: number
}
