/**
 * 沉浸光感按钮组件
 * 实现外发光层 + 控件主体层 + 内阴影层的三层视觉模型
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
      return 'transparent'
    } else {
      return 'transparent'
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
  
  build() {
    Stack() {
      // 外发光层
      if (this.getGlowParams().blur > 0) {
        Column()
          .width(this.getButtonSize() + 16)
          .height(this.getButtonSize() + 16)
          .borderRadius(BorderRadius.FULL)
          .backgroundColor(this.type === 'secondary' ? Colors.GLOW_BLUE : Colors.GLOW_BLUE)
          .opacity(this.getGlowParams().opacity)
          .blur(this.getGlowParams().blur)
      }
      
      // 控件主体层
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
      .width(this.label === '' ? this.getButtonSize() : 'auto')
      .height(this.getButtonSize())
      .padding(this.label === '' ? 0 : { left: 24, right: 24 })
      .borderRadius(BorderRadius.MEDIUM)
      .backgroundColor(this.getBackgroundColor())
      .borderWidth(this.type === 'outline' ? 2 : 0)
      .borderColor(this.isActive ? Colors.BRAND_PRIMARY : Colors.TEXT_TERTIARY_LIGHT)
      .shadow({
        radius: this.isActive ? 12 : 4,
        color: this.isActive ? Colors.GLOW_BLUE : '#1A000000',
        offsetX: 0,
        offsetY: this.isPressed ? 2 : 4
      })
    }
    .width(this.label === '' ? this.getButtonSize() + 16 : 'auto')
    .height(this.getButtonSize() + 16)
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
      } else if (event.type === TouchType.Up) {
        this.isPressed = false
        if (this.onAction) {
          this.onAction()
        }
      } else if (event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
  }
}
