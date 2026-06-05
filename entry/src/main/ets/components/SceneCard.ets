/**
 * 场景卡片组件
 * 实现快捷场景触发
 */
import { Colors, GlowConfig, BorderRadius, FontSize, Spacing, ComponentSize } from '../common/DesignConstants'

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
  
  // 计算光晕参数
  private getGlowParams(): GlowParams {
    if (this.isPressed) {
      return { blur: GlowConfig.GLOW_BLUR_PRESSED, opacity: GlowConfig.GLOW_OPACITY_PRESSED }
    }
    
    if (this.isHovered) {
      return { blur: GlowConfig.GLOW_BLUR_HOVER, opacity: GlowConfig.GLOW_OPACITY_HOVER }
    }
    
    if (this.scene.isActive) {
      return { blur: GlowConfig.GLOW_BLUR_ACTIVE, opacity: GlowConfig.GLOW_OPACITY_ACTIVE }
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
      // 外发光层
      if (this.getGlowParams().blur > 0) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(BorderRadius.LARGE)
          .backgroundColor(this.scene.color)
          .opacity(this.getGlowParams().opacity)
          .blur(this.getGlowParams().blur)
      }
      
      // 卡片主体
      Column({ space: 12 }) {
        // 场景图标
        Text(this.scene.icon)
          .fontSize(40)
          .opacity(this.scene.isActive ? 1 : 0.7)
        
        // 场景名称
        Text(this.scene.name)
          .fontSize(FontSize.BODY1)
          .fontWeight(500)
          .fontColor(this.scene.isActive ? Colors.TEXT_PRIMARY_LIGHT : Colors.TEXT_SECONDARY_LIGHT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        // 关联设备数
        if (this.scene.deviceCount > 0) {
          Text(`${this.scene.deviceCount}个设备`)
            .fontSize(FontSize.CAPTION1)
            .fontColor(Colors.TEXT_TERTIARY_LIGHT)
        }
      }
      .width('100%')
      .height(ComponentSize.SCENE_CARD_SIZE)
      .justifyContent(FlexAlign.Center)
      .padding(Spacing.LG)
      .borderRadius(BorderRadius.LARGE)
      .backgroundColor(this.scene.isActive ? this.scene.color : '#FFFFFF')
      .linearGradient(this.scene.isActive ? {
        angle: 135,
        colors: [
          [this.scene.color, 0],
          [this.scene.color + 'CC', 1]  // 80% 透明度
        ]
      } : undefined)
      .shadow({
        radius: this.scene.isActive ? 16 : 4,
        color: this.scene.isActive ? this.scene.color + '40' : '#1A000000',  // 25% 透明度
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
