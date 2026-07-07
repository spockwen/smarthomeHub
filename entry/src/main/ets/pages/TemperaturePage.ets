/**
 * 温度详情页 - 室内温度监控与控制
 * 展示温度历史趋势、相关设备控制
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius } from '../common/DesignConstants'
import router from '@ohos.router'

@Entry
@Component
struct TemperaturePage {
  @StorageLink('temperature') temperature: number = 26
  @StorageLink('airOn') airOn: boolean = false
  @StorageLink('heaterOn') heaterOn: boolean = false
  
  @State private targetTemp: number = 26
  @State private tempHistory: number[] = [24, 25, 26, 27, 26, 25, 24, 25, 26, 27, 28, 27]
  
  build() {
    Column() {
      // 顶部导航栏
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          // 当前温度卡片
          this.CurrentTempCard()
          
          // 温度趋势图
          this.TempTrendCard()
          
          // 温度控制
          this.TempControlCard()
          
          // 相关设备
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
    .backgroundColor(Colors.BG_LIGHT)
  }
  
  // 导航栏
  @Builder NavigationBar() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        .onClick(() => {
          router.back()
        })
      
      Text('室内温度')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        .margin({ left: Spacing.MD })
      
      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 当前温度卡片
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
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.LG })
        
        Blank()
        
        // 温度状态指示
        Column({ space: 4 }) {
          Text(this.getTempStatus())
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor(this.getTempStatusColor())
          
          Text(this.getTempAdvice())
            .fontSize(FontSize.CAPTION1)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
  
  // 温度趋势图
  @Builder TempTrendCard() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('温度趋势')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Blank()
        
        Text('近12小时')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
      }
      .width('100%')
      
      // 简易柱状图
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
      
      // 图例
      Row({ space: Spacing.LG }) {
        this.LegendItem('偏热', Colors.WARNING)
        this.LegendItem('舒适', Colors.BRAND_PRIMARY)
        this.LegendItem('偏冷', Colors.BRAND_SECONDARY)
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 图例项
  @Builder LegendItem(label: string, color: string) {
    Row({ space: 4 }) {
      Column()
        .width(12)
        .height(12)
        .borderRadius(2)
        .backgroundColor(color)
      
      Text(label)
        .fontSize(FontSize.CAPTION2)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
    }
  }
  
  // 温度控制
  @Builder TempControlCard() {
    Column({ space: Spacing.MD }) {
      Text('目标温度')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
      Row() {
        // 减少按钮
        Column() {
          Text('-')
            .fontSize(28)
            .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(Colors.BG_LIGHT)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.targetTemp > 16) {
            this.targetTemp--
          }
        })
        
        // 目标温度显示
        Text(`${this.targetTemp}℃`)
          .fontSize(36)
          .fontWeight(700)
          .fontColor(Colors.BRAND_PRIMARY)
          .margin({ left: Spacing.XL, right: Spacing.XL })
        
        // 增加按钮
        Column() {
          Text('+')
            .fontSize(28)
            .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(Colors.BG_LIGHT)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.targetTemp < 30) {
            this.targetTemp++
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      
      // 快捷设置
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
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 快捷温度按钮
  @Builder QuickTempButton(label: string, temp: number, icon: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(20)
      
      Text(`${temp}℃`)
        .fontSize(FontSize.BODY1)
        .fontWeight(600)
        .fontColor(this.targetTemp === temp ? Colors.BRAND_PRIMARY : Colors.TEXT_PRIMARY_LIGHT)
      
      Text(label)
        .fontSize(FontSize.CAPTION2)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
    }
    .layoutWeight(1)
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(this.targetTemp === temp ? '#E3F2FD' : Colors.BG_LIGHT)
    .onClick(() => {
      this.targetTemp = temp
    })
  }
  
  // 相关设备
  @Builder RelatedDevicesCard() {
    Column({ space: Spacing.MD }) {
      Text('温控设备')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
      // 空调
      this.DeviceItem('❄️', '空调', this.airOn, (isOn: boolean) => {
        DeviceStore.setAirOn(isOn)
      })
      
      // 暖气
      this.DeviceItem('🔥', '暖气', this.heaterOn, (isOn: boolean) => {
        DeviceStore.setHeaterOn(isOn)
      })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 设备项
  @Builder DeviceItem(icon: string, name: string, isOn: boolean, onToggle: (isOn: boolean) => void) {
    Row() {
      Text(icon)
        .fontSize(24)
      
      Text(name)
        .fontSize(FontSize.BODY1)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
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
  
  // 获取温度状态
  private getTempStatus(): string {
    if (this.temperature >= 28) return '偏热'
    if (this.temperature <= 22) return '偏冷'
    return '舒适'
  }
  
  // 获取温度状态颜色
  private getTempStatusColor(): string {
    if (this.temperature >= 28) return Colors.WARNING
    if (this.temperature <= 22) return Colors.BRAND_SECONDARY
    return Colors.SUCCESS
  }
  
  // 获取温度建议
  private getTempAdvice(): string {
    if (this.temperature >= 28) return '建议开启空调'
    if (this.temperature <= 22) return '建议开启暖气'
    return '温度适宜'
  }
  
  // 获取柱状图高度
  private getBarHeight(temp: number): number {
    const minTemp = 20
    const maxTemp = 32
    const minHeight = 20
    const maxHeight = 100
    const ratio = (temp - minTemp) / (maxTemp - minTemp)
    return minHeight + ratio * (maxHeight - minHeight)
  }
}
