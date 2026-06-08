/**
 * 设备卡片组件
 * 实现沉浸光感设备状态展示 + 毛玻璃基底 + 动态光效
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

// 光晕偏移接口
interface GlowOffset {
  x: number
  y: number
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
  @State private glowPulse: number = 0  // 呼吸动画相位
  @State private touchX: number = 0
  @State private touchY: number = 0
  
  // 定时器ID
  private breathingTimer: number = -1
  
  // 初始化设备状态
  aboutToAppear(): void {
    this.deviceState = this.device.isOn
    
    // 启动呼吸动画
    if (this.deviceState && this.device.status !== 'offline') {
      this.startBreathingAnimation()
    }
  }
  
  aboutToDisappear(): void {
    // 清理定时器
    if (this.breathingTimer !== -1) {
      clearInterval(this.breathingTimer)
    }
  }
  
  // 启动呼吸动画
  private startBreathingAnimation(): void {
    this.breathingTimer = setInterval(() => {
      this.glowPulse = (this.glowPulse + 0.05) % (2 * Math.PI)
    }, 50)
  }
  
  // 停止呼吸动画
  private stopBreathingAnimation(): void {
    if (this.breathingTimer !== -1) {
      clearInterval(this.breathingTimer)
      this.breathingTimer = -1
    }
  }
  
  // 计算卡片背景色
  private getCardColor(): string {
    if (this.device.status === 'offline') {
      return 'rgba(240, 240, 240, 0.8)'
    }
    if (this.deviceState) {
      return 'rgba(255, 255, 255, 0.7)'  // 毛玻璃基底
    }
    return 'rgba(250, 250, 250, 0.6)'
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
    
    // 呼吸动画影响透明度
    const breatheOpacity = 0.3 + 0.1 * Math.sin(this.glowPulse)
    return { blur: GlowConfig.GLOW_BLUR_ACTIVE, opacity: breatheOpacity }
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
  
  // 计算光晕偏移（跟随触摸点）
  private getGlowOffset(): GlowOffset {
    if (this.isPressed) {
      const offset: GlowOffset = {
        x: (this.touchX - 100) * 0.2,
        y: (this.touchY - 60) * 0.2
      }
      return offset
    }
    const defaultOffset: GlowOffset = { x: 0, y: 0 }
    return defaultOffset
  }
  
  build() {
    Stack() {
      // 第二层：卡片主体（毛玻璃基底）
      Column({ space: this.compact ? 4 : 6 }) {
        // 顶部：图标和开关
        Row() {
          // 设备图标（带光晕）
          Stack() {
            // 图标光晕
            if (this.deviceState && this.device.status !== 'offline') {
              Column()
                .width(this.compact ? 48 : 56)
                .height(this.compact ? 48 : 56)
                .borderRadius(BorderRadius.FULL)
                .backgroundColor(Colors.GLOW_BLUE)
                .opacity(0.3)
                .blur(8)
            }
            
            // 图标本体
            Text(this.device.icon)
              .fontSize(this.compact ? 32 : 40)
              .opacity(this.device.status === 'offline' ? 0.5 : 1)
          }
          .width(this.compact ? 48 : 56)
          .height(this.compact ? 48 : 56)
          
          Blank()
          
          // 开关
          HaloToggle({
            isOn: this.deviceState,
            disabled: this.device.status === 'offline',
            onChange: (value: boolean) => {
              this.deviceState = value
              if (value) {
                this.startBreathingAnimation()
              } else {
                this.stopBreathingAnimation()
              }
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
      .padding(this.compact ? 6 : 10)
      .borderRadius(BorderRadius.LARGE)
      .backgroundColor(this.getCardColor())
      // 毛玻璃效果
      .backgroundBlurStyle(BlurStyle.Thin, { colorMode: ThemeColorMode.LIGHT, scale: 0.6 })
      .borderWidth(1)
      .borderColor('rgba(255, 255, 255, 0.3)')
      // 阴影效果（深度视觉）
      .shadow({
        radius: this.deviceState ? 16 : 8,
        color: this.deviceState ? Colors.GLOW_BLUE : '#1A000000',
        offsetX: 0,
        offsetY: this.isPressed ? 2 : 6
      })
    }
    .width('100%')
    .scale({ x: this.getScale(), y: this.getScale() })
    .animation({
      duration: GlowConfig.ANIM_DURATION_NORMAL,
      curve: Curve.EaseOut
    })
    .hitTestBehavior(HitTestMode.Default)
    .onHover((isHover: boolean) => {
      this.isHovered = isHover
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
        this.touchX = event.touches[0].x
        this.touchY = event.touches[0].y
      } else if (event.type === TouchType.Move) {
        this.touchX = event.touches[0].x
        this.touchY = event.touches[0].y
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
