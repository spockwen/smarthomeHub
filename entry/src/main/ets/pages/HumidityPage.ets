/**
 * 湿度详情页 - 室内湿度监控与控制
 * 展示湿度历史趋势、相关设备控制
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import router from '@ohos.router'

@Entry
@Component
struct HumidityPage {
  @StorageLink('humidity') humidity: number = 72
  @StorageProp('isDarkMode') isDark: boolean = false
  
  @State private targetHumidity: number = 60
  @State private humidityHistory: number[] = [65, 68, 70, 72, 75, 73, 70, 68, 65, 63, 60, 62]
  
  build() {
    Column() {
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          this.CurrentHumidityCard()
          this.HumidityTrendCard()
          this.HumidityControlCard()
          this.HumidityAdviceCard()
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
      
      Text('室内湿度')
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
  
  @Builder CurrentHumidityCard() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text('💧')
          .fontSize(40)
        
        Column({ space: 4 }) {
          Text(`${this.humidity}%`)
            .fontSize(48)
            .fontWeight(700)
            .fontColor(Colors.BRAND_SECONDARY)
          
          Text('当前室内湿度')
            .fontSize(FontSize.BODY2)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.LG })
        
        Blank()
        
        Column({ space: 4 }) {
          Text(this.getHumidityStatus())
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor(this.getHumidityStatusColor())
          
          Text(this.getHumidityAdvice())
            .fontSize(FontSize.CAPTION1)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
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
  
  @Builder HumidityTrendCard() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('湿度趋势')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
        
        Blank()
        
        Text('近12小时')
          .fontSize(FontSize.CAPTION1)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }
      .width('100%')
      
      Row({ space: 4 }) {
        ForEach(this.humidityHistory, (humidity: number, index: number) => {
          Column() {
            Column()
              .width(16)
              .height(this.getBarHeight(humidity))
              .borderRadius(4)
              .backgroundColor(humidity >= 70 ? Colors.BRAND_SECONDARY : 
                             humidity <= 40 ? Colors.WARNING : 
                             Colors.SUCCESS)
          }
          .height(100)
          .justifyContent(FlexAlign.End)
        })
      }
      .width('100%')
      .height(120)
      
      Row({ space: Spacing.LG }) {
        this.LegendItem('偏湿', Colors.BRAND_SECONDARY)
        this.LegendItem('舒适', Colors.SUCCESS)
        this.LegendItem('偏干', Colors.WARNING)
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
  
  @Builder HumidityControlCard() {
    Column({ space: Spacing.MD }) {
      Text('目标湿度')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
      Row() {
        Column() {
          Text('-')
            .fontSize(28)
            .fontColor(ThemeColors.textPrimary(this.isDark))
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(ThemeColors.bg(this.isDark))
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.targetHumidity > 30) {
            this.targetHumidity -= 5
          }
        })
        
        Text(`${this.targetHumidity}%`)
          .fontSize(36)
          .fontWeight(700)
          .fontColor(Colors.BRAND_SECONDARY)
          .margin({ left: Spacing.XL, right: Spacing.XL })
        
        Column() {
          Text('+')
            .fontSize(28)
            .fontColor(ThemeColors.textPrimary(this.isDark))
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(ThemeColors.bg(this.isDark))
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.targetHumidity < 80) {
            this.targetHumidity += 5
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      
      Row({ space: Spacing.SM }) {
        this.QuickHumidityButton('干燥', 40, '🏜️')
        this.QuickHumidityButton('舒适', 60, '😊')
        this.QuickHumidityButton('湿润', 70, '💦')
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder QuickHumidityButton(label: string, humidity: number, icon: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(20)
      
      Text(`${humidity}%`)
        .fontSize(FontSize.BODY1)
        .fontWeight(600)
        .fontColor(this.targetHumidity === humidity ? Colors.BRAND_SECONDARY : ThemeColors.textPrimary(this.isDark))
      
      Text(label)
        .fontSize(FontSize.CAPTION2)
        .fontColor(ThemeColors.textSecondary(this.isDark))
    }
    .layoutWeight(1)
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(this.targetHumidity === humidity ? ThemeColors.selectedBg(this.isDark) : ThemeColors.bg(this.isDark))
    .onClick(() => {
      this.targetHumidity = humidity
    })
  }
  
  @Builder HumidityAdviceCard() {
    Column({ space: Spacing.MD }) {
      Text('湿度小贴士')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
      Column({ space: Spacing.SM }) {
        this.AdviceItem('🏠', '室内最佳湿度范围：40%-70%')
        this.AdviceItem('💧', '湿度过高易滋生细菌，建议通风除湿')
        this.AdviceItem('🏜️', '湿度过低易导致皮肤干燥，建议使用加湿器')
        this.AdviceItem('🌡️', '温度与湿度相互影响，需综合考虑')
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
  
  private getHumidityStatus(): string {
    if (this.humidity >= 70) return '偏湿'
    if (this.humidity <= 40) return '偏干'
    return '舒适'
  }
  
  private getHumidityStatusColor(): string {
    if (this.humidity >= 70) return Colors.BRAND_SECONDARY
    if (this.humidity <= 40) return Colors.WARNING
    return Colors.SUCCESS
  }
  
  private getHumidityAdvice(): string {
    if (this.humidity >= 70) return '建议通风除湿'
    if (this.humidity <= 40) return '建议使用加湿器'
    return '湿度适宜'
  }
  
  private getBarHeight(humidity: number): number {
    const minHumidity = 20
    const maxHumidity = 90
    const minHeight = 20
    const maxHeight = 100
    const ratio = (humidity - minHumidity) / (maxHumidity - minHumidity)
    return minHeight + ratio * (maxHeight - minHeight)
  }
}
