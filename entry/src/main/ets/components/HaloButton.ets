/**
 * 沉浸光感按钮组件
 * 实现毛玻璃基底 + 动态光源跟随 + 三层视觉模型（外发光层+控件主体层+内阴影层）
 */
import { Colors, GlowConfig, BorderRadius, FontSize, TouchTarget } from '../common/DesignConstants'

// 按钮尺寸类型
export type HaloButtonSize = 'small' | 'medium' | 'large'

// 按钮类型
export type HaloButtonType = 'primary' | 'secondary' | 'outline' | 'ghost'

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
export struct HaloButton {
  // 按钮文字
  @Prop label: string = ''
  // 按钮图标
  @Prop icon: string = ''
  // 按钮尺寸
  @Prop buttonSize: HaloButtonSize = 'medium'
  // 按钮类型
  @Prop type: HaloButtonType = 'primary'
  // 是否禁用
  @Prop disabled: boolean = false
  // 是否激活态
  @Prop isActive: boolean = false
  // 点击回调
  onAction?: () => void
  
  // 内部状态
  @State private isHovered: boolean = false
  @State private isPressed: boolean = false
  @State private touchX: number = 0  // 触摸点X坐标（用于动态光源）
  @State private touchY: number = 0  // 触摸点Y坐标
  @State private glowScale: number = 1  // 光晕扩散动画
  @State private glowOpacity: number = 0  // 光晕透明度
  
  // 计算按钮尺寸
  private getButtonSize(): number {
    switch (this.buttonSize) {
      case 'small':
        return 36
      case 'medium':
        return 48
      case 'large':
        return 56
      default:
        return 48
    }
  }
  
  // 计算背景色
  private getBackgroundColor(): string {
    if (this.disabled) {
      return '#33000000'
    }
    
    if (this.type === 'primary') {
      return this.isActive ? Colors.BRAND_PRIMARY : Colors.BRAND_PRIMARY
    } else if (this.type === 'secondary') {
      return this.isActive ? Colors.BRAND_SECONDARY : Colors.BRAND_SECONDARY
    } else if (this.type === 'outline') {
      return 'rgba(255, 255, 255, 0.6)'  // 毛玻璃基底
    } else {
      return 'rgba(255, 255, 255, 0.4)'  // 毛玻璃基底
    }
  }
  
  // 计算文字颜色
  private getTextColor(): string {
    if (this.disabled) {
      return Colors.TEXT_TERTIARY_LIGHT
    }
    
    if (this.type === 'primary' || this.type === 'secondary') {
      return '#FFFFFF'
    } else {
      return this.isActive ? Colors.BRAND_PRIMARY : Colors.TEXT_PRIMARY_LIGHT
    }
  }
  
  // 计算光晕参数
  private getGlowParams(): GlowParams {
    if (this.disabled) {
      return { blur: 0, opacity: 0 }
    }
    
    if (this.isPressed) {
      return { blur: GlowConfig.GLOW_BLUR_PRESSED, opacity: GlowConfig.GLOW_OPACITY_PRESSED }
    }
    
    if (this.isHovered) {
      return { blur: GlowConfig.GLOW_BLUR_HOVER, opacity: GlowConfig.GLOW_OPACITY_HOVER }
    }
    
    if (this.isActive) {
      return { blur: GlowConfig.GLOW_BLUR_ACTIVE, opacity: GlowConfig.GLOW_OPACITY_ACTIVE }
    }
    
    return { blur: GlowConfig.GLOW_BLUR_DEFAULT, opacity: GlowConfig.GLOW_OPACITY_DEFAULT }
  }
  
  // 计算缩放比例
  private getScale(): number {
    if (this.disabled) return 1
    if (this.isPressed) return GlowConfig.SCALE_PRESSED
    if (this.isHovered) return GlowConfig.SCALE_HOVER
    return 1
  }
  
  // 计算亮度（按压时提升）
  private getBrightness(): number {
    if (this.disabled) return 1
    if (this.isPressed) return 1.15  // 按压时亮度提升15%
    if (this.isHovered) return 1.05
    return 1
  }
  
  // 计算光晕位置（跟随触摸点）
  private getGlowOffset(): GlowOffset {
    const buttonSize = this.getButtonSize()
    const centerX = buttonSize / 2
    const centerY = buttonSize / 2
    
    if (this.isPressed) {
      // 光源跟随触摸点移动
      const offset: GlowOffset = {
        x: (this.touchX - centerX) * 0.3,  // 跟随系数0.3，产生微妙的跟随效果
        y: (this.touchY - centerY) * 0.3
      }
      return offset
    }
    
    const defaultOffset: GlowOffset = { x: 0, y: 0 }
    return defaultOffset
  }
  
  build() {
    Stack() {
      // 第一层：外发光层（动态光源）
      if (this.getGlowParams().blur > 0 || this.glowOpacity > 0) {
        Column()
          .width(this.getButtonSize() + 32)
          .height(this.getButtonSize() + 32)
          .borderRadius(BorderRadius.FULL)
          .linearGradient({
            angle: 135,
            colors: [
              [this.type === 'secondary' ? Colors.GLOW_BLUE : Colors.GLOW_BLUE, 0],
              ['transparent', 1]
            ]
          })
          .opacity(Math.max(this.getGlowParams().opacity, this.glowOpacity))
          .blur(this.getGlowParams().blur)
          .scale({ x: this.glowScale, y: this.glowScale })
          .translate(this.getGlowOffset())
          .animation({
            duration: 300,
            curve: Curve.EaseOut
          })
      }
      
      // 第二层：控件主体层（毛玻璃基底）
      Column() {
        Row({ space: 8 }) {
          if (this.icon !== '') {
            Text(this.icon)
              .fontSize(this.buttonSize === 'small' ? 16 : 20)
          }
          
          if (this.label !== '') {
            Text(this.label)
              .fontSize(this.buttonSize === 'small' ? FontSize.CAPTION1 : FontSize.BODY1)
              .fontColor(this.getTextColor())
              .fontWeight(500)
          }
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width(this.label === '' ? this.getButtonSize() : 'auto')
      .height(this.getButtonSize())
      .padding(this.label === '' ? 0 : { left: 24, right: 24 })
      .borderRadius(BorderRadius.MEDIUM)
      .backgroundColor(this.getBackgroundColor())
      .borderWidth(this.type === 'outline' ? 2 : 0)
      .borderColor(this.isActive ? Colors.BRAND_PRIMARY : Colors.TEXT_TERTIARY_LIGHT)
      // 毛玻璃效果（仅对outline和ghost类型）
      .backgroundBlurStyle(
        (this.type === 'outline' || this.type === 'ghost') ? BlurStyle.Thin : BlurStyle.NONE,
        { colorMode: ThemeColorMode.LIGHT, scale: 0.8 }
      )
      // 亮度效果
      .brightness(this.getBrightness())
      // 阴影效果（内阴影层）
      .shadow({
        radius: this.isPressed ? 8 : (this.isActive ? 12 : 4),
        color: this.isPressed ? '#40000000' : (this.isActive ? Colors.GLOW_BLUE : '#1A000000'),
        offsetX: 0,
        offsetY: this.isPressed ? 1 : 4
      })
    }
    .width(this.label === '' ? this.getButtonSize() + 32 : 'auto')
    .height(this.getButtonSize() + 32)
    .scale({ x: this.getScale(), y: this.getScale() })
    .animation({
      duration: GlowConfig.ANIM_DURATION_NORMAL,
      curve: Curve.EaseOut
    })
    .enabled(!this.disabled)
    .hitTestBehavior(HitTestMode.Block)
    .onHover((isHover: boolean) => {
      this.isHovered = isHover
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
        // 记录触摸点位置
        this.touchX = event.touches[0].x
        this.touchY = event.touches[0].y
        
        // 触发光晕扩散动画
        this.glowScale = 1.2
        this.glowOpacity = 0.4
        
        // 延迟启动扩散动画
        setTimeout(() => {
          this.glowScale = 1.5
          this.glowOpacity = 0.2
        }, 100)
        
      } else if (event.type === TouchType.Move) {
        // 实时更新触摸点位置（光源跟随）
        this.touchX = event.touches[0].x
        this.touchY = event.touches[0].y
        
      } else if (event.type === TouchType.Up) {
        this.isPressed = false
        // 重置光晕动画
        this.glowScale = 1
        this.glowOpacity = 0
        
        if (this.onAction) {
          this.onAction()
        }
      } else if (event.type === TouchType.Cancel) {
        this.isPressed = false
        this.glowScale = 1
        this.glowOpacity = 0
      }
    })
  }
}
