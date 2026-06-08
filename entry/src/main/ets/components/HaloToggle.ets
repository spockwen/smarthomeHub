/**
 * 沉浸光感开关组件
 * 简洁的状态切换开关
 */
import { Colors, GlowConfig, BorderRadius, ComponentSize } from '../common/DesignConstants'

@Component
export struct HaloToggle {
  // 是否开启
  @Link isOn: boolean
  // 是否禁用
  @Prop disabled: boolean = false
  // 状态变化回调
  onChange?: (value: boolean) => void
  
  // 内部状态
  @State private isHovered: boolean = false
  @State private isPressed: boolean = false
  @State private thumbOffset: number = 0  // 拖拽偏移量
  
  // 开关尺寸
  private readonly WIDTH = ComponentSize.TOGGLE_WIDTH
  private readonly HEIGHT = ComponentSize.TOGGLE_HEIGHT
  private readonly THUMB_SIZE = ComponentSize.TOGGLE_THUMB_SIZE
  private readonly TRACK_PADDING = 2  // 轨道内边距
  
  // 计算滑块位置
  private getThumbPosition(): number {
    const maxOffset = this.WIDTH - this.THUMB_SIZE - this.TRACK_PADDING * 2
    const basePosition = this.isOn ? maxOffset : 0
    return basePosition + this.thumbOffset
  }
  
  // 计算轨道背景色
  private getTrackColor(): string {
    if (this.disabled) {
      return Colors.TEXT_TERTIARY_LIGHT
    }
    return this.isOn ? Colors.BRAND_PRIMARY : Colors.TEXT_TERTIARY_LIGHT
  }
  
  // 计算光晕参数
  private getGlowBlur(): number {
    if (this.disabled) return 0
    if (this.isPressed) return GlowConfig.GLOW_BLUR_PRESSED
    if (this.isHovered) return GlowConfig.GLOW_BLUR_HOVER
    if (this.isOn) return GlowConfig.GLOW_BLUR_ACTIVE
    return 0
  }
  
  build() {
    Stack() {
      // 外发光层
      if (this.getGlowBlur() > 0 && this.isOn) {
        Column()
          .width(this.WIDTH + 20)
          .height(this.HEIGHT + 20)
          .borderRadius(BorderRadius.FULL)
          .linearGradient({
            angle: 90,
            colors: [
              [Colors.GLOW_BLUE, 0],
              ['transparent', 1]
            ]
          })
          .opacity(0.5)
          .blur(this.getGlowBlur())
      }
      
      // 轨道层
      Stack({ alignContent: Alignment.Start }) {
        // 内部扫光效果 (开启时)
        if (this.isOn) {
          Row()
            .width('100%')
            .height('100%')
            .borderRadius(BorderRadius.FULL)
            .linearGradient({
              angle: 90,
              colors: [
                [Colors.BRAND_SECONDARY, 0],
                [Colors.BRAND_PRIMARY, 1]
              ]
            })
            .opacity(0.4)
        }
        
        // 滑块
        Stack() {
          // 滑块光晕
          if (this.isOn && !this.disabled) {
            Column()
              .width(this.THUMB_SIZE + 8)
              .height(this.THUMB_SIZE + 8)
              .borderRadius(BorderRadius.FULL)
              .backgroundColor(Colors.GLOW_WHITE)
              .opacity(0.4)
              .blur(6)
          }
          
          // 滑块本体
          Column()
            .width(this.THUMB_SIZE)
            .height(this.THUMB_SIZE)
            .borderRadius(BorderRadius.FULL)
            .backgroundColor('#FFFFFF')
            .shadow({
              radius: this.isPressed ? 10 : 6,
              color: this.isPressed ? Colors.GLOW_BLUE : '#33000000',
              offsetX: 0,
              offsetY: this.isPressed ? 1 : 2
            })
        }
        .margin({ left: this.TRACK_PADDING + this.getThumbPosition() })
      }
      .width(this.WIDTH)
      .height(this.HEIGHT)
      .borderRadius(BorderRadius.FULL)
      .backgroundColor(this.getTrackColor())
      .padding(this.TRACK_PADDING)
    }
    .width(this.WIDTH + 20)
    .height(this.HEIGHT + 20)
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
        this.isOn = !this.isOn
        if (this.onChange) {
          this.onChange(this.isOn)
        }
      } else if (event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
  }
}