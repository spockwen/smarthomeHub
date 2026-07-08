/**
 * 场景卡片组件
 * 实现光感场景触发 + 沉浸激活态视觉反馈
 */
import { Colors, GlowConfig, BorderRadius, FontSize, Spacing, ComponentSize, ThemeColors } from '../common/DesignConstants'

// 场景数据模型
export interface SceneModel {
  id: string
  name: string
  icon: string
  color: string  // 场景主题色
  isActive: boolean
  deviceCount: number  // 关联设备数
}

// 光晕参数接口
interface GlowParams {
  blur: number
  opacity: number
}

@Component
export struct SceneCard {
  // 场景数据
  @Prop scene: SceneModel = {
    id: '',
    name: '场景',
    icon: '🏠',
    color: Colors.BRAND_PRIMARY,
    isActive: false,
    deviceCount: 0
  }
  // 点击回调
  onTap?: () => void
  
  // 内部状态
  @State private isHovered: boolean = false
  @State private isPressed: boolean = false
  @StorageProp('isDarkMode') isDark: boolean = false
  
  // 计算光晕参数
  private getGlowParams(): GlowParams {
    if (this.isPressed) {
      return { blur: GlowConfig.GLOW_BLUR_PRESSED, opacity: GlowConfig.GLOW_OPACITY_PRESSED }
    }
    
    if (this.isHovered) {
      return { blur: GlowConfig.GLOW_BLUR_HOVER, opacity: GlowConfig.GLOW_OPACITY_HOVER }
    }
    
    return { blur: 0, opacity: 0 }
  }
  
  // 计算缩放比例
  private getScale(): number {
    if (this.isPressed) return GlowConfig.SCALE_PRESSED
    if (this.isHovered) return GlowConfig.SCALE_HOVER
    return 1
  }
  
  build() {
    Stack() {
      // 第一层：外发光层（沉浸光感）
      if (this.getGlowParams().blur > 0) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(BorderRadius.LARGE)
          .linearGradient({
            angle: 135,
            colors: [
              [this.scene.color, 0],
              ['transparent', 1]
            ]
          })
          .opacity(this.getGlowParams().opacity)
          .blur(this.getGlowParams().blur)
          .animation({
            duration: 200,
            curve: Curve.EaseOut
          })
      }
      
      // 第二层：卡片主体
      Column({ space: 12 }) {
        // 场景图标（带光晕）
        Stack() {
          // 图标光晕
          if (this.scene.isActive) {
            Column()
              .width(60)
              .height(60)
              .borderRadius(BorderRadius.FULL)
              .backgroundColor(this.scene.color)
              .opacity(0.4)
              .blur(10)
          }
          
          // 图标本体
          Text(this.scene.icon)
            .fontSize(40)
            .opacity(this.scene.isActive ? 1 : 0.7)
        }
        .width(60)
        .height(60)
        
        // 场景名称
        Text(this.scene.name)
          .fontSize(FontSize.BODY1)
          .fontWeight(500)
          .fontColor(this.scene.isActive ? '#FFFFFF' : ThemeColors.textSecondary(this.isDark))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        // 关联设备数
        if (this.scene.deviceCount > 0) {
          Text(`${this.scene.deviceCount}个设备`)
            .fontSize(FontSize.CAPTION1)
            .fontColor(this.scene.isActive ? 'rgba(255, 255, 255, 0.8)' : ThemeColors.textTertiary(this.isDark))
        }
      }
      .width('100%')
      .height(ComponentSize.SCENE_CARD_SIZE)
      .justifyContent(FlexAlign.Center)
      .padding(Spacing.LG)
      .borderRadius(BorderRadius.LARGE)
      .backgroundColor(this.scene.isActive ? this.scene.color : ThemeColors.cardBg(this.isDark))
      // 毛玻璃效果（未激活时）
      .backgroundBlurStyle(
        this.scene.isActive ? BlurStyle.NONE : BlurStyle.Thin,
        { colorMode: ThemeColorMode.LIGHT, scale: 0.6 }
      )
      // 渐变效果（激活时）
      .linearGradient(this.scene.isActive ? {
        angle: 135,
        colors: [
          [this.scene.color, 0],
          [this.scene.color + 'CC', 1]  // 80% 透明度
        ]
      } : undefined)
      // 阴影效果（offsetY保持不变，避免按下时卡片视觉下移）
      .shadow({
        radius: this.scene.isActive ? 20 : 8,
        color: this.scene.isActive ? this.scene.color + '60' : ThemeColors.cardShadow(this.isDark),  // 37.5% 透明度
        offsetX: 0,
        offsetY: 8
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
