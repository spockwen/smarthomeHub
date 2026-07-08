/**
 * 沉浸光感滑块组件
 * 实现带光效的数值调节 + 光源跟随指尖移动
 */
import { Colors, GlowConfig, BorderRadius, ComponentSize, FontSize, ThemeColors } from '../common/DesignConstants'

@Component
export struct HaloSlider {
  // 当前值
  @Link value: number
  // 最小值
  @Prop min: number = 0
  // 最大值
  @Prop max: number = 100
  // 步长
  @Prop step: number = 1
  // 是否显示数值
  @Prop showValue: boolean = true
  // 单位
  @Prop unit: string = ''
  // 是否禁用
  @Prop disabled: boolean = false
  // 值变化回调
  onChange?: (value: number) => void
  
  // 内部状态
  @State private isHovered: boolean = false
  @State private isDragging: boolean = false
  @State private touchX: number = 0  // 触摸点X坐标
  @State private lightGlowPosition: number = 0  // 光源位置
  @State private glowIntensity: number = 0  // 光晕强度
  @StorageProp('isDarkMode') isDark: boolean = false
  
  // 尺寸常量
  private readonly TRACK_HEIGHT = ComponentSize.SLIDER_TRACK_HEIGHT
  private readonly THUMB_SIZE = ComponentSize.SLIDER_THUMB_SIZE
  private readonly THUMB_SIZE_DRAGGING = ComponentSize.SLIDER_THUMB_SIZE_DRAGGING
  
  // 计算进度百分比
  private getProgress(): number {
    return (this.value - this.min) / (this.max - this.min)
  }
  
  // 计算滑块尺寸
  private getThumbSize(): number {
    return this.isDragging ? this.THUMB_SIZE_DRAGGING : this.THUMB_SIZE
  }
  
  // 计算光晕参数
  private getGlowBlur(): number {
    if (this.disabled) return 0
    if (this.isDragging) return GlowConfig.GLOW_BLUR_ACTIVE
    if (this.isHovered) return GlowConfig.GLOW_BLUR_HOVER
    return 0
  }
  
  // 计算光源位置（跟随触摸点）
  private getLightPosition(): number {
    if (this.isDragging) {
      // 光源跟随触摸点移动
      return this.touchX
    }
    // 默认跟随滑块位置
    return this.getProgress() * 100
  }
  
  // 根据触摸位置计算值
  private calculateValue(x: number, width: number): number {
    let progress = x / width
    progress = Math.max(0, Math.min(1, progress))
    let newValue = this.min + progress * (this.max - this.min)
    
    // 应用步长
    if (this.step > 0) {
      newValue = Math.round(newValue / this.step) * this.step
    }
    
    return Math.max(this.min, Math.min(this.max, newValue))
  }
  
  build() {
    Column({ space: 12 }) {
      // 数值显示
      if (this.showValue) {
        Row() {
          Text(`${Math.round(this.value)}${this.unit}`)
            .fontSize(FontSize.TITLE2)
            .fontWeight(700)
            .fontColor(this.disabled ? ThemeColors.textTertiary(this.isDark) : ThemeColors.textPrimary(this.isDark))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      
      // 滑块轨道
      Stack() {
        // 外发光层（跟随光源位置）
        if (this.getGlowBlur() > 0) {
          Row()
            .width(60)
            .height(this.THUMB_SIZE + 20)
            .borderRadius(BorderRadius.FULL)
            .linearGradient({
              angle: 90,
              colors: [
                ['transparent', 0],
                [Colors.GLOW_BLUE, 0.5],
                ['transparent', 1]
              ]
            })
            .opacity(this.isDragging ? 0.5 : 0.3)
            .blur(this.getGlowBlur())
            .margin({ left: `${this.getLightPosition()}%` })
            .translate({ x: -30 })
        }
        
        // 轨道背景
        Stack({ alignContent: Alignment.Start }) {
          // 已选中轨道（渐变光效）
          Row()
            .width(`${this.getProgress() * 100}%`)
            .height(this.TRACK_HEIGHT)
            .borderRadius(BorderRadius.FULL)
            .linearGradient({
              angle: 90,
              colors: [
                [Colors.BRAND_SECONDARY, 0],
                [Colors.BRAND_PRIMARY, 1]
              ]
            })
          
          // 流动光线效果（拖拽时）
          if (this.isDragging) {
            Row()
              .width(30)
              .height(this.TRACK_HEIGHT)
              .borderRadius(BorderRadius.FULL)
              .linearGradient({
                angle: 90,
                colors: [
                  ['transparent', 0],
                  ['rgba(255, 255, 255, 0.8)', 0.5],
                  ['transparent', 1]
                ]
              })
              .margin({ left: `${this.getProgress() * 100}%` })
              .translate({ x: -15 })
              .blur(3)
          }
          
          // 滑块
          Stack() {
            // 滑块光晕
            if (this.isDragging) {
              Column()
                .width(this.getThumbSize() + 12)
                .height(this.getThumbSize() + 12)
                .borderRadius(BorderRadius.FULL)
                .backgroundColor(Colors.GLOW_BLUE)
                .opacity(0.4)
                .blur(8)
            }
            
            // 滑块本体
            Column()
              .width(this.getThumbSize())
              .height(this.getThumbSize())
              .borderRadius(BorderRadius.FULL)
              .backgroundColor('#FFFFFF')
              .shadow({
                radius: this.isDragging ? 14 : 8,
                color: this.isDragging ? ThemeColors.glowBlue(this.isDark) : '#33000000',
                offsetX: 0,
                offsetY: this.isDragging ? 0 : 2
              })
              // 亮度提升（拖拽时）
              .brightness(this.isDragging ? 1.1 : 1)
          }
          .margin({ left: `${this.getProgress() * 100}%` })
          .translate({ x: -this.getThumbSize() / 2 })
          .animation({
            duration: GlowConfig.ANIM_DURATION_FAST,
            curve: Curve.FastOutSlowIn
          })
        }
        .width('100%')
        .height(this.TRACK_HEIGHT)
        .borderRadius(BorderRadius.FULL)
        .backgroundColor(this.disabled ? ThemeColors.textTertiary(this.isDark) : '#E5E5E5')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(this.THUMB_SIZE + 20)
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
          this.isDragging = true
          this.touchX = event.touches[0].x
        } else if (event.type === TouchType.Move || event.type === TouchType.Down) {
          // 实时更新触摸点位置（光源跟随）
          this.touchX = event.touches[0].x
          
          // 计算触摸位置对应的值
          const width = 300  // 假设轨道宽度，实际需要动态获取
          const x = event.touches[0].x
          this.value = this.calculateValue(x, width)
        } else if (event.type === TouchType.Up) {
          this.isDragging = false
          if (this.onChange) {
            this.onChange(this.value)
          }
        } else if (event.type === TouchType.Cancel) {
          this.isDragging = false
        }
      })
    }
    .width('100%')
  }
}
