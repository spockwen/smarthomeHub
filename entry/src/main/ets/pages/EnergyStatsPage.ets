/**
 * 能耗统计页 - 用电趋势图 + 分类饼图
 * 基于 HarmonyOS Design 规范实现
 */
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'

// 时间范围类型
type TimeRange = 'day' | 'week' | 'month'

// 能耗数据点
interface EnergyDataPoint {
  time: string
  value: number
}

// 设备能耗数据
interface DeviceEnergy {
  id: string
  name: string
  icon: string
  energy: number
  percentage: number
}

@Entry
@Component
export struct EnergyStatsPage {
  // 当前时间范围
  @State private timeRange: TimeRange = 'day'
  
  // 总能耗
  @State private totalEnergy: number = 8.5
  
  // 同比数据
  @State private comparedPercentage: number = -12.3  // 负数表示下降
  
  // 用电趋势数据
  @State private trendData: EnergyDataPoint[] = [
    { time: '00:00', value: 0.2 },
    { time: '04:00', value: 0.1 },
    { time: '08:00', value: 0.8 },
    { time: '12:00', value: 1.2 },
    { time: '16:00', value: 1.5 },
    { time: '20:00', value: 2.3 },
    { time: '24:00', value: 2.4 }
  ]
  
  // 分类能耗数据
  @State private categoryData = [
    { name: '照明', value: 2.5, color: '#FFB800', percentage: 29 },
    { name: '空调', value: 4.2, color: '#007DFF', percentage: 49 },
    { name: '家电', value: 1.3, color: '#00C854', percentage: 15 },
    { name: '其他', value: 0.5, color: '#6B7280', percentage: 7 }
  ]
  
  // 设备能耗排行
  @State private deviceRanking: DeviceEnergy[] = [
    { id: '1', name: '空调', icon: '❄️', energy: 4.2, percentage: 49 },
    { id: '2', name: '客厅灯', icon: '💡', energy: 1.5, percentage: 18 },
    { id: '3', name: '卧室灯', icon: '💡', energy: 0.8, percentage: 9 },
    { id: '4', name: '智能电视', icon: '📺', energy: 0.7, percentage: 8 },
    { id: '5', name: '智能插座', icon: '🔌', energy: 0.6, percentage: 7 }
  ]
  
  // 时间范围选项
  private readonly timeRanges = [
    { id: 'day', name: '今日' },
    { id: 'week', name: '本周' },
    { id: 'month', name: '本月' }
  ]
  
  build() {
    Column() {
      // 顶部导航栏
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          // 总能耗卡片
          this.TotalEnergyCard()
          
          // 用电趋势图
          this.TrendChart()
          
          // 分类能耗
          this.CategoryChart()
          
          // 设备能耗排行
          this.DeviceRanking()
          
          // 节能建议
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
    .backgroundColor(Colors.BG_LIGHT)
  }
  
  // 导航栏
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
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
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
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 总能耗卡片
  @Builder TotalEnergyCard() {
    Column({ space: Spacing.LG }) {
      // 时间范围选择
      Row({ space: Spacing.SM }) {
        ForEach(this.timeRanges, (range: { id: string, name: string }) => {
          Text(range.name)
            .fontSize(FontSize.BODY2)
            .fontColor(this.timeRange === range.id ? Colors.BRAND_PRIMARY : Colors.TEXT_SECONDARY_LIGHT)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(BorderRadius.MEDIUM)
            .backgroundColor(this.timeRange === range.id ? Colors.BRAND_PRIMARY + '15' : 'transparent')
            .onClick(() => {
              this.timeRange = range.id as TimeRange
              // 更新数据
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
      
      // 总能耗数值
      Column({ space: 8 }) {
        Row({ space: 4 }) {
          Text(this.totalEnergy.toFixed(1))
            .fontSize(48)
            .fontWeight(700)
            .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          
          Text('kWh')
            .fontSize(FontSize.TITLE3)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        
        // 同比数据
        Row({ space: 4 }) {
          Text(this.comparedPercentage < 0 ? '↓' : '↑')
            .fontSize(16)
            .fontColor(this.comparedPercentage < 0 ? Colors.SUCCESS : Colors.ERROR)
          
          Text(`${Math.abs(this.comparedPercentage).toFixed(1)}%`)
            .fontSize(FontSize.BODY2)
            .fontColor(this.comparedPercentage < 0 ? Colors.SUCCESS : Colors.ERROR)
          
          Text('同比昨日')
            .fontSize(FontSize.BODY2)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
      }
    }
    .width('100%')
    .padding(Spacing.XL)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
  
  // 用电趋势图
  @Builder TrendChart() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('📈')
          .fontSize(20)
        
        Text('用电趋势')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      .width('100%')
      
      // 简化折线图（使用 Canvas 或自定义绘制）
      Column() {
        // 数据点可视化
        Row({ space: 4 }) {
          ForEach(this.trendData, (point: EnergyDataPoint, index: number) => {
            Column({ space: 4 }) {
              // 柱状图
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
              
              // 时间标签
              if (index % 2 === 0) {
                Text(point.time.split(':')[0] + 'h')
                  .fontSize(FontSize.CAPTION2)
                  .fontColor(Colors.TEXT_TERTIARY_LIGHT)
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
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 分类能耗饼图
  @Builder CategoryChart() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('📊')
          .fontSize(20)
        
        Text('分类能耗')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      .width('100%')
      
      // 分类列表
      Column({ space: Spacing.SM }) {
        ForEach(this.categoryData, (item: { name: string, value: number, color: string, percentage: number }) => {
          Row() {
            // 颜色标记
            Column()
              .width(12)
              .height(12)
              .borderRadius(6)
              .backgroundColor(item.color)
            
            // 名称
            Text(item.name)
              .fontSize(FontSize.BODY2)
              .fontColor(Colors.TEXT_PRIMARY_LIGHT)
              .margin({ left: Spacing.SM })
            
            Blank()
            
            // 数值和百分比
            Row({ space: 8 }) {
              Text(`${item.value}kWh`)
                .fontSize(FontSize.BODY2)
                .fontWeight(500)
                .fontColor(Colors.TEXT_PRIMARY_LIGHT)
              
              Text(`${item.percentage}%`)
                .fontSize(FontSize.CAPTION1)
                .fontColor(Colors.TEXT_SECONDARY_LIGHT)
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
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 设备能耗排行
  @Builder DeviceRanking() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('🏆')
          .fontSize(20)
        
        Text('设备能耗排行')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      .width('100%')
      
      // 排行列表
      Column({ space: Spacing.SM }) {
        ForEach(this.deviceRanking, (device: DeviceEnergy, index: number) => {
          Row() {
            // 排名
            Text(`${index + 1}`)
              .fontSize(FontSize.BODY1)
              .fontWeight(600)
              .fontColor(index < 3 ? Colors.BRAND_PRIMARY : Colors.TEXT_TERTIARY_LIGHT)
              .width(24)
            
            // 设备图标
            Text(device.icon)
              .fontSize(24)
              .margin({ left: Spacing.SM })
            
            // 设备名称
            Text(device.name)
              .fontSize(FontSize.BODY2)
              .fontColor(Colors.TEXT_PRIMARY_LIGHT)
              .margin({ left: Spacing.SM })
              .layoutWeight(1)
            
            // 能耗数值
            Text(`${device.energy}kWh`)
              .fontSize(FontSize.BODY2)
              .fontWeight(500)
              .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          }
          .width('100%')
          .padding(Spacing.SM)
          .borderRadius(BorderRadius.MEDIUM)
          .backgroundColor('#F5F5F5')
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 节能建议
  @Builder EnergyTips() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('💡')
          .fontSize(20)
        
        Text('节能建议')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      .width('100%')
      
      // 建议列表
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
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 建议项
  @Builder TipItem(text: string, icon: string) {
    Row({ space: Spacing.SM }) {
      Text(icon)
        .fontSize(20)
      
      Text(text)
        .fontSize(FontSize.BODY2)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.SM)
  }
}
