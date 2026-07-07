/**
 * 湿度详情页 - 室内湿度监控与控制
 * 展示湿度历史趋势、相关设备控制
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius } from '../common/DesignConstants'
import router from '@ohos.router'

@Entry
@Component
struct HumidityPage {
  @StorageLink('humidity') humidity: number = 72
  
  @State private targetHumidity: number = 60
  @State private humidityHistory: number[] = [65, 68, 70, 72, 75, 73, 70, 68, 65, 63, 60, 62]
  
  build() {
    Column() {
      // 顶部导航栏
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          // 当前湿度卡片
          this.CurrentHumidityCard()
          
          // 湿度趋势图
          this.HumidityTrendCard()
          
          // 湿度控制
          this.HumidityControlCard()
          
          // 湿度建议
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
      
      Text('室内湿度')
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
  
  // 当前湿度卡片
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
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.LG })
        
        Blank()
        
        // 湿度状态指示
        Column({ space: 4 }) {
          Text(this.getHumidityStatus())
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor(this.getHumidityStatusColor())
          
          Text(this.getHumidityAdvice())
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
  
  // 湿度趋势图
  @Builder HumidityTrendCard() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('湿度趋势')
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
      
      // 图例
      Row({ space: Spacing.LG }) {
        this.LegendItem('偏湿', Colors.BRAND_SECONDARY)
        this.LegendItem('舒适', Colors.SUCCESS)
        this.LegendItem('偏干', Colors.WARNING)
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
  
  // 湿度控制
  @Builder HumidityControlCard() {
    Column({ space: Spacing.MD }) {
      Text('目标湿度')
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
          if (this.targetHumidity > 30) {
            this.targetHumidity -= 5
          }
        })
        
        // 目标湿度显示
        Text(`${this.targetHumidity}%`)
          .fontSize(36)
          .fontWeight(700)
          .fontColor(Colors.BRAND_SECONDARY)
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
          if (this.targetHumidity < 80) {
            this.targetHumidity += 5
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      
      // 快捷设置
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
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 快捷湿度按钮
  @Builder QuickHumidityButton(label: string, humidity: number, icon: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(20)
      
      Text(`${humidity}%`)
        .fontSize(FontSize.BODY1)
        .fontWeight(600)
        .fontColor(this.targetHumidity === humidity ? Colors.BRAND_SECONDARY : Colors.TEXT_PRIMARY_LIGHT)
      
      Text(label)
        .fontSize(FontSize.CAPTION2)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
    }
    .layoutWeight(1)
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(this.targetHumidity === humidity ? '#E1F5FE' : Colors.BG_LIGHT)
    .onClick(() => {
      this.targetHumidity = humidity
    })
  }
  
  // 湿度建议卡片
  @Builder HumidityAdviceCard() {
    Column({ space: Spacing.MD }) {
      Text('湿度小贴士')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
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
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 建议项
  @Builder AdviceItem(icon: string, text: string) {
    Row({ space: Spacing.SM }) {
      Text(icon)
        .fontSize(20)
      
      Text(text)
        .fontSize(FontSize.BODY2)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        .layoutWeight(1)
    }
    .width('100%')
  }
  
  // 获取湿度状态
  private getHumidityStatus(): string {
    if (this.humidity >= 70) return '偏湿'
    if (this.humidity <= 40) return '偏干'
    return '舒适'
  }
  
  // 获取湿度状态颜色
  private getHumidityStatusColor(): string {
    if (this.humidity >= 70) return Colors.BRAND_SECONDARY
    if (this.humidity <= 40) return Colors.WARNING
    return Colors.SUCCESS
  }
  
  // 获取湿度建议
  private getHumidityAdvice(): string {
    if (this.humidity >= 70) return '建议通风除湿'
    if (this.humidity <= 40) return '建议使用加湿器'
    return '湿度适宜'
  }
  
  // 获取柱状图高度
  private getBarHeight(humidity: number): number {
    const minHumidity = 20
    const maxHumidity = 90
    const minHeight = 20
    const maxHeight = 100
    const ratio = (humidity - minHumidity) / (maxHumidity - minHumidity)
    return minHeight + ratio * (maxHeight - minHeight)
  }
}
