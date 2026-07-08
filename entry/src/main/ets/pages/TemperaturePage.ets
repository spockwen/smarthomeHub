/**
 * 温度详情页 - 室内温度监控与控制
 * 展示温度历史趋势、相关设备控制
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import router from '@ohos.router'

@Entry
@Component
struct TemperaturePage {
  @StorageLink('temperature') temperature: number = 26
  @StorageLink('airOn') airOn: boolean = false
  @StorageLink('heaterOn') heaterOn: boolean = false
  @StorageProp('isDarkMode') isDark: boolean = false
  
  @State private targetTemp: number = 26
  @State private tempHistory: number[] = [24, 25, 26, 27, 26, 25, 24, 25, 26, 27, 28, 27]
  
  build() {
    Column() {
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          this.CurrentTempCard()
          this.TempTrendCard()
          this.TempControlCard()
          this.RelatedDevicesCard()
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
      
      Text('室内温度')
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
  
  @Builder CurrentTempCard() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text('🌡️')
          .fontSize(40)
        
        Column({ space: 4 }) {
          Text(`${this.temperature}℃`)
            .fontSize(48)
            .fontWeight(700)
            .fontColor(Colors.BRAND_PRIMARY)
          
          Text('当前室内温度')
            .fontSize(FontSize.BODY2)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.LG })
        
        Blank()
        
        Column({ space: 4 }) {
          Text(this.getTempStatus())
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor(this.getTempStatusColor())
          
          Text(this.getTempAdvice())
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
  
  @Builder TempTrendCard() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('温度趋势')
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
        ForEach(this.tempHistory, (temp: number, index: number) => {
          Column() {
            Column()
              .width(16)
              .height(this.getBarHeight(temp))
              .borderRadius(4)
              .backgroundColor(temp >= 28 ? Colors.WARNING : 
                             temp <= 22 ? Colors.BRAND_SECONDARY : 
                             Colors.BRAND_PRIMARY)
          }
          .height(100)
          .justifyContent(FlexAlign.End)
        })
      }
      .width('100%')
      .height(120)
      
      Row({ space: Spacing.LG }) {
        this.LegendItem('偏热', Colors.WARNING)
        this.LegendItem('舒适', Colors.BRAND_PRIMARY)
        this.LegendItem('偏冷', Colors.BRAND_SECONDARY)
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
  
  @Builder TempControlCard() {
    Column({ space: Spacing.MD }) {
      Text('目标温度')
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
          if (this.targetTemp > 16) {
            this.targetTemp--
          }
        })
        
        Text(`${this.targetTemp}℃`)
          .fontSize(36)
          .fontWeight(700)
          .fontColor(Colors.BRAND_PRIMARY)
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
          if (this.targetTemp < 30) {
            this.targetTemp++
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      
      Row({ space: Spacing.SM }) {
        this.QuickTempButton('制冷', 24, '❄️')
        this.QuickTempButton('舒适', 26, '😊')
        this.QuickTempButton('制热', 28, '🔥')
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder QuickTempButton(label: string, temp: number, icon: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(20)
      
      Text(`${temp}℃`)
        .fontSize(FontSize.BODY1)
        .fontWeight(600)
        .fontColor(this.targetTemp === temp ? Colors.BRAND_PRIMARY : ThemeColors.textPrimary(this.isDark))
      
      Text(label)
        .fontSize(FontSize.CAPTION2)
        .fontColor(ThemeColors.textSecondary(this.isDark))
    }
    .layoutWeight(1)
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(this.targetTemp === temp ? ThemeColors.selectedBg(this.isDark) : ThemeColors.bg(this.isDark))
    .onClick(() => {
      this.targetTemp = temp
    })
  }
  
  @Builder RelatedDevicesCard() {
    Column({ space: Spacing.MD }) {
      Text('温控设备')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
      this.DeviceItem('❄️', '空调', this.airOn, (isOn: boolean) => {
        DeviceStore.setAirOn(isOn)
      })
      
      this.DeviceItem('🔥', '暖气', this.heaterOn, (isOn: boolean) => {
        DeviceStore.setHeaterOn(isOn)
      })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder DeviceItem(icon: string, name: string, isOn: boolean, onToggle: (isOn: boolean) => void) {
    Row() {
      Text(icon)
        .fontSize(24)
      
      Text(name)
        .fontSize(FontSize.BODY1)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .margin({ left: Spacing.MD })
      
      Blank()
      
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange((isOn: boolean) => {
          onToggle(isOn)
        })
        .selectedColor(Colors.BRAND_PRIMARY)
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
  }
  
  private getTempStatus(): string {
    if (this.temperature >= 28) return '偏热'
    if (this.temperature <= 22) return '偏冷'
    return '舒适'
  }
  
  private getTempStatusColor(): string {
    if (this.temperature >= 28) return Colors.WARNING
    if (this.temperature <= 22) return Colors.BRAND_SECONDARY
    return Colors.SUCCESS
  }
  
  private getTempAdvice(): string {
    if (this.temperature >= 28) return '建议开启空调'
    if (this.temperature <= 22) return '建议开启暖气'
    return '温度适宜'
  }
  
  private getBarHeight(temp: number): number {
    const minTemp = 20
    const maxTemp = 32
    const minHeight = 20
    const maxHeight = 100
    const ratio = (temp - minTemp) / (maxTemp - minTemp)
    return minHeight + ratio * (maxHeight - minHeight)
  }
}
