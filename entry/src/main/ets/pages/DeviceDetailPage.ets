/**
 * 设备详情页 - 亮度/色温调节 + 情景模式
 * 基于 HarmonyOS Design 规范实现
 */
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'
import { HaloSlider } from '../components/HaloSlider'
import { HaloToggle } from '../components/HaloToggle'

// 设备详情参数
export interface DeviceDetailParams {
  id: string
  name: string
  icon: string
  room: string
}

@Entry
@Component
export struct DeviceDetailPage {
  // 路由参数
  @State private deviceParams: DeviceDetailParams = {
    id: '',
    name: '设备详情',
    icon: '💡',
    room: '客厅'
  }
  
  // 设备状态
  @State private isOn: boolean = true
  @State private brightness: number = 80
  @State private colorTemp: number = 4000  // 色温 (K)
  @State private selectedMode: string = 'normal'
  
  // 情景模式
  private readonly modes = [
    { id: 'normal', name: '日常', icon: '☀️', color: Colors.BRAND_PRIMARY },
    { id: 'reading', name: '阅读', icon: '📖', color: '#FFB800' },
    { id: 'relax', name: '休闲', icon: '🌙', color: '#8B5CF6' },
    { id: 'night', name: '夜灯', icon: '🌃', color: '#6B7280' }
  ]
  
  build() {
    Column() {
      // 顶部导航栏
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.XL }) {
          // 设备状态卡片
          this.StatusCard()
          
          // 亮度调节
          this.BrightnessSection()
          
          // 色温调节
          this.ColorTempSection()
          
          // 情景模式
          this.ModeSection()
          
          // 定时设置
          this.TimerSection()
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
      
      Text(this.deviceParams.name)
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
      Blank()
      
      HaloButton({
        icon: '⚙️',
        buttonSize: 'medium',
        type: 'ghost'
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 设备状态卡片
  @Builder StatusCard() {
    Column({ space: Spacing.LG }) {
      // 设备图标和状态
      Row() {
        Column({ space: 8 }) {
          Text(this.deviceParams.icon)
            .fontSize(64)
            .opacity(this.isOn ? 1 : 0.5)
          
          Text(this.isOn ? '运行中' : '已关闭')
            .fontSize(FontSize.BODY2)
            .fontColor(this.isOn ? Colors.SUCCESS : Colors.TEXT_SECONDARY_LIGHT)
        }
        
        Blank()
        
        // 开关
        Column({ space: 8 }) {
          HaloToggle({
            isOn: this.isOn,
            onChange: (value: boolean) => {
              this.isOn = value
            }
          })
        }
      }
      .width('100%')
      
      // 房间信息
      Row() {
        Text('📍')
          .fontSize(16)
        
        Text(this.deviceParams.room)
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
      }
    }
    .width('100%')
    .padding(Spacing.XL)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .shadow({
      radius: this.isOn ? 16 : 4,
      color: this.isOn ? Colors.GLOW_BLUE : '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
  }
  
  // 亮度调节
  @Builder BrightnessSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('💡')
          .fontSize(20)
        
        Text('亮度')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      
      HaloSlider({
        value: this.brightness,
        min: 0,
        max: 100,
        step: 5,
        showValue: true,
        unit: '%',
        onChange: (value: number) => {
          this.brightness = value
        }
      })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 色温调节
  @Builder ColorTempSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('🎨')
          .fontSize(20)
        
        Text('色温')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      
      HaloSlider({
        value: this.colorTemp,
        min: 2700,
        max: 6500,
        step: 100,
        showValue: true,
        unit: 'K',
        onChange: (value: number) => {
          this.colorTemp = value
        }
      })
      
      // 色温预览
      Row({ space: Spacing.SM }) {
        Column()
          .width(40)
          .height(20)
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor('#FFA500')  // 暖光
        
        Column()
          .width('100%')
          .height(20)
          .borderRadius(BorderRadius.SMALL)
          .linearGradient({
            angle: 90,
            colors: [
              ['#FFA500', 0],
              ['#FFFFFF', 0.5],
              ['#87CEEB', 1]
            ]
          })
        
        Column()
          .width(40)
          .height(20)
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor('#87CEEB')  // 冷光
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 情景模式
  @Builder ModeSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('🎭')
          .fontSize(20)
        
        Text('情景模式')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      .width('100%')
      
      // 模式网格
      Grid() {
        ForEach(this.modes, (mode: { id: string, name: string, icon: string, color: string }) => {
          GridItem() {
            Column({ space: 8 }) {
              Text(mode.icon)
                .fontSize(32)
              
              Text(mode.name)
                .fontSize(FontSize.CAPTION1)
                .fontColor(this.selectedMode === mode.id ? Colors.TEXT_PRIMARY_LIGHT : Colors.TEXT_SECONDARY_LIGHT)
            }
            .width('100%')
            .height(80)
            .justifyContent(FlexAlign.Center)
            .borderRadius(BorderRadius.MEDIUM)
            .backgroundColor(this.selectedMode === mode.id ? mode.color + '20' : '#F5F5F5')
            .borderWidth(this.selectedMode === mode.id ? 2 : 0)
            .borderColor(mode.color)
            .onClick(() => {
              this.selectedMode = mode.id
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(Spacing.SM)
      .columnsGap(Spacing.SM)
      .width('100%')
      .height(100)
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 定时设置
  @Builder TimerSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('⏰')
          .fontSize(20)
        
        Text('定时设置')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Blank()
        
        HaloButton({
          label: '添加',
          buttonSize: 'small',
          type: 'outline'
        })
      }
      .width('100%')
      
      // 定时列表
      Column({ space: Spacing.SM }) {
        this.TimerItem('07:00', '自动开启', true)
        this.TimerItem('22:00', '自动关闭', true)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 定时项
  @Builder TimerItem(time: string, action: string, enabled: boolean) {
    Row() {
      Text(time)
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
      Text(action)
        .fontSize(FontSize.BODY2)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        .margin({ left: Spacing.SM })
      
      Blank()
      
      HaloToggle({
        isOn: enabled
      })
    }
    .width('100%')
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor('#F5F5F5')
  }
}
