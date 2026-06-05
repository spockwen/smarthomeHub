/**
 * 设备卡片组件
 * 实现沉浸光感设备状态展示
 */
import { Colors, GlowConfig, BorderRadius, FontSize, Spacing, ComponentSize } from '../common/DesignConstants'
import { HaloToggle } from './HaloToggle'

// 设备状态类型
export type DeviceStatus = 'online' | 'offline' | 'warning'

// 设备数据模型
export interface DeviceModel {
  id: string
  name: string
  icon: string
  room: string
  status: DeviceStatus
  isOn: boolean
  value?: string  // 如亮度、温度等
}

// 光晕参数接口
interface GlowParams {
  blur: number
  opacity: number
}

@Component
export struct DeviceCard {
  // 设备数据
  @Prop device: DeviceModel = {
    id: '',
    name: '设备',
    icon: '💡',
    room: '客厅',
    status: 'online',
    isOn: false
  }
  // 是否紧凑模式（用于首页）
  @Prop compact: boolean = false
  // 点击回调
  onTap?: () => void
  // 状态变化回调
  onToggle?: (isOn: boolean) => void
  
  // 内部状态
  @State private isHovered: boolean = false
  @State private isPressed: boolean = false
  @State private deviceState: boolean = false  // 设备开关状态
  
  // 初始化设备状态
  aboutToAppear(): void {
    this.deviceState = this.device.isOn
  }
  
  // 计算卡片背景色
  private getCardColor(): string {
    if (this.device.status === 'offline') {
      return '#F0F0F0'
    }
    if (this.deviceState) {
      return '#FFFFFF'
    }
    return '#FAFAFA'
  }
  
  // 计算光晕参数
  private getGlowParams(): GlowParams {
    if (!this.deviceState || this.device.status === 'offline') {
      return { blur: 0, opacity: 0 }
    }
    
    if (this.isPressed) {
      return { blur: GlowConfig.GLOW_BLUR_PRESSED, opacity: GlowConfig.GLOW_OPACITY_PRESSED }
    }
    
    if (this.isHovered) {
      return { blur: GlowConfig.GLOW_BLUR_HOVER, opacity: GlowConfig.GLOW_OPACITY_HOVER }
    }
    
    return { blur: GlowConfig.GLOW_BLUR_ACTIVE, opacity: GlowConfig.GLOW_OPACITY_ACTIVE }
  }
  
  // 计算缩放比例
  private getScale(): number {
    if (this.isPressed) return GlowConfig.SCALE_PRESSED
    if (this.isHovered) return GlowConfig.SCALE_HOVER
    return 1
  }
  
  // 获取状态文字
  private getStatusText(): string {
    if (this.device.status === 'offline') {
      return '离线'
    }
    if (this.device.status === 'warning') {
      return '异常'
    }
    if (this.deviceState) {
      return this.device.value || '运行中'
    }
    return '已关闭'
  }
  
  // 获取状态颜色
  private getStatusColor(): string {
    if (this.device.status === 'offline') {
      return Colors.TEXT_TERTIARY_LIGHT
    }
    if (this.device.status === 'warning') {
      return Colors.WARNING
    }
    if (this.deviceState) {
      return Colors.SUCCESS
    }
    return Colors.TEXT_SECONDARY_LIGHT
  }
  
  build() {
    Stack() {
      // 外发光层
      if (this.getGlowParams().blur > 0) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(BorderRadius.LARGE)
          .backgroundColor(Colors.GLOW_BLUE)
          .opacity(this.getGlowParams().opacity)
          .blur(this.getGlowParams().blur)
      }
      
      // 卡片主体
      Column({ space: this.compact ? 8 : 12 }) {
        // 顶部：图标和开关
        Row() {
          // 设备图标
          Text(this.device.icon)
            .fontSize(this.compact ? 32 : 40)
            .opacity(this.device.status === 'offline' ? 0.5 : 1)
          
          Blank()
          
          // 开关
          HaloToggle({
            isOn: this.deviceState,
            disabled: this.device.status === 'offline',
            onChange: (value: boolean) => {
              this.deviceState = value
              if (this.onToggle) {
                this.onToggle(value)
              }
            }
          })
        }
        .width('100%')
        
        // 底部：设备信息
        Column({ space: 4 }) {
          // 设备名称
          Text(this.device.name)
            .fontSize(this.compact ? FontSize.BODY2 : FontSize.BODY1)
            .fontWeight(500)
            .fontColor(this.device.status === 'offline' ? Colors.TEXT_TERTIARY_LIGHT : Colors.TEXT_PRIMARY_LIGHT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          
          // 房间和状态
          if (!this.compact) {
            Row({ space: 8 }) {
              Text(this.device.room)
                .fontSize(FontSize.CAPTION1)
                .fontColor(Colors.TEXT_SECONDARY_LIGHT)
              
              Text('·')
                .fontSize(FontSize.CAPTION1)
                .fontColor(Colors.TEXT_TERTIARY_LIGHT)
              
              Text(this.getStatusText())
                .fontSize(FontSize.CAPTION1)
                .fontColor(this.getStatusColor())
            }
          } else {
            Text(this.getStatusText())
              .fontSize(FontSize.CAPTION1)
              .fontColor(this.getStatusColor())
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(this.compact ? Spacing.SM : Spacing.LG)
      .borderRadius(BorderRadius.LARGE)
      .backgroundColor(this.getCardColor())
      .shadow({
        radius: this.deviceState ? 12 : 4,
        color: this.deviceState ? Colors.GLOW_BLUE : '#1A000000',
        offsetX: 0,
        offsetY: this.isPressed ? 2 : 4
      })
    }
    .width('100%')
    .scale({ x: this.getScale(), y: this.getScale() })
    .animation({
      duration: GlowConfig.ANIM_DURATION_NORMAL,
      curve: Curve.EaseOut
    })
    .hitTestBehavior(HitTestMode.Block)
    .onHover((isHover: boolean) => {
      this.isHovered = isHover
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up) {
        this.isPressed = false
        if (this.onTap) {
          this.onTap()
        }
      } else if (event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
  }
}
