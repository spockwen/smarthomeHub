/**
 * SmartHome AIHub 全局设计规范常量
 * 基于 HarmonyOS Design 官方规范
 * 文档版本: v1.0
 */

// ==================== 色彩系统 ====================
export class Colors {
  // 品牌色
  static readonly BRAND_PRIMARY = '#007DFF'      // 品牌主色
  static readonly BRAND_SECONDARY = '#00A5FF'    // 品牌辅色
  
  // 功能色
  static readonly SUCCESS = '#00C854'            // 成功色
  static readonly WARNING = '#FFB800'            // 警告色
  static readonly ERROR = '#FF3B30'              // 错误色
  
  // 背景色 (Light Mode)
  static readonly BG_LIGHT = '#F2F5F7'           // 页面背景
  static readonly SURFACE_LIGHT = '#FFFFFF'      // 卡片背景
  static readonly ELEVATED_LIGHT = '#FFFFFF'     // 悬浮元素
  static readonly DIVIDER_LIGHT = '#0F000000'    // 分割线 (8% 黑色)
  
  // 背景色 (Dark Mode)
  static readonly BG_DARK = '#0D0D0D'
  static readonly SURFACE_DARK = '#1A1A1A'
  static readonly ELEVATED_DARK = '#242424'
  static readonly DIVIDER_DARK = '#24FFFFFF'     // 14% 白色
  
  // 文字色 (Light Mode)
  static readonly TEXT_PRIMARY_LIGHT = '#E6000000'    // 主文字
  static readonly TEXT_SECONDARY_LIGHT = '#99000000'  // 次要文字
  static readonly TEXT_TERTIARY_LIGHT = '#66000000'   // 辅助文字
  static readonly TEXT_DISABLED_LIGHT = '#33000000'   // 禁用文字
  
  // 文字色 (Dark Mode)
  static readonly TEXT_PRIMARY_DARK = '#E6FFFFFF'
  static readonly TEXT_SECONDARY_DARK = '#99FFFFFF'
  static readonly TEXT_TERTIARY_DARK = '#66FFFFFF'
  static readonly TEXT_DISABLED_DARK = '#33FFFFFF'
  
  // 光感色彩
  static readonly GLOW_BLUE = '#33007DFF'        // 蓝色光晕 (30%)
  static readonly GLOW_BLUE_STRONG = '#66007DFF' // 蓝色光晕 (60%)
  static readonly GLOW_GREEN = '#3300C854'       // 绿色光晕
  static readonly GLOW_WHITE = '#33FFFFFF'       // 白色光晕
}

// ==================== 字体规范 ====================
export class FontSize {
  static readonly DISPLAY = 36       // 页面大标题
  static readonly TITLE1 = 28        // 模块标题
  static readonly TITLE2 = 22        // 卡片标题
  static readonly TITLE3 = 18        // 子模块标题
  static readonly BODY1 = 16         // 正文内容
  static readonly BODY2 = 14         // 次要正文
  static readonly CAPTION1 = 12      // 辅助说明
  static readonly CAPTION2 = 10      // 极端辅助信息
  static readonly NUMERIC = 32       // 数据展示
}

export class FontWeight {
  static readonly REGULAR = 400
  static readonly MEDIUM = 500
  static readonly BOLD = 700
}

// ==================== 间距系统 (4pt 基准网格) ====================
export class Spacing {
  static readonly XS = 4      // 组件内部最小间距
  static readonly SM = 8      // 列表项内部间距
  static readonly MD = 12     // 区块内间距
  static readonly LG = 16     // 区块间标准间距
  static readonly XL = 24     // 大区块分隔
  static readonly XXL = 32    // 页面全局间距
}

// ==================== 圆角规范 ====================
export class BorderRadius {
  static readonly SMALL = 8       // 小控件
  static readonly MEDIUM = 12     // 表单控件
  static readonly LARGE = 16      // 卡片/容器
  static readonly XLARGE = 24     // 大模态弹窗
  static readonly FULL = 999      // 圆形
}

// ==================== 光感参数配置 ====================
export class GlowConfig {
  // 外发光层参数
  static readonly GLOW_BLUR_DEFAULT = 0
  static readonly GLOW_BLUR_HOVER = 10
  static readonly GLOW_BLUR_PRESSED = 6
  static readonly GLOW_BLUR_ACTIVE = 20
  
  // 光感透明度
  static readonly GLOW_OPACITY_DEFAULT = 0
  static readonly GLOW_OPACITY_HOVER = 0.2
  static readonly GLOW_OPACITY_PRESSED = 0.3
  static readonly GLOW_OPACITY_ACTIVE = 0.4
  
  // 动画时长 (毫秒)
  static readonly ANIM_DURATION_FAST = 100
  static readonly ANIM_DURATION_NORMAL = 200
  static readonly ANIM_DURATION_SLOW = 300
  static readonly ANIM_DURATION_BREATH = 3000    // 呼吸动画
  
  // 缩放比例
  static readonly SCALE_PRESSED = 0.97
  static readonly SCALE_HOVER = 1.02
}

// ==================== 触控热区最小尺寸 ====================
export class TouchTarget {
  static readonly MIN_SIZE_PHONE = 44      // 手机最小触控热区
  static readonly MIN_SIZE_TABLET = 44     // 平板最小触控热区
  static readonly MIN_SIZE_TV = 64         // 智慧屏最小触控热区
  static readonly MIN_SIZE_WATCH = 40      // 手表最小触控热区
}

// ==================== 组件尺寸规范 ====================
export class ComponentSize {
  // 设备图标
  static readonly DEVICE_ICON_SMALL = 32
  static readonly DEVICE_ICON_MEDIUM = 48
  static readonly DEVICE_ICON_LARGE = 64
  static readonly DEVICE_ICON_XLARGE = 96
  
  // 场景卡片
  static readonly SCENE_CARD_SIZE = 120
  static readonly SCENE_ICON_SIZE = 48
  
  // 设备列表项
  static readonly DEVICE_LIST_ITEM_HEIGHT = 72
  
  // 开关控件
  static readonly TOGGLE_WIDTH = 52
  static readonly TOGGLE_HEIGHT = 28
  static readonly TOGGLE_THUMB_SIZE = 24
  
  // 滑块
  static readonly SLIDER_TRACK_HEIGHT = 6
  static readonly SLIDER_THUMB_SIZE = 24
  static readonly SLIDER_THUMB_SIZE_DRAGGING = 28
  
  // TabBar
  static readonly TABBAR_HEIGHT = 56
  static readonly TABBAR_ICON_SIZE = 24
}

// ==================== 阴影参数 ====================
// 阴影参数接口
export interface ShadowParams {
  radius: number
  color: string
  offsetX: number
  offsetY: number
}

export class ShadowConfig {
  // 卡片阴影
  static readonly CARD_SHADOW: ShadowParams = {
    radius: 8,
    color: Colors.DIVIDER_LIGHT,
    offsetX: 0,
    offsetY: 4
  }
  
  // 悬浮按钮阴影
  static readonly FAB_SHADOW: ShadowParams = {
    radius: 12,
    color: '#1A000000',
    offsetX: 0,
    offsetY: 6
  }
  
  // 光感阴影 (激活态)
  static readonly GLOW_SHADOW: ShadowParams = {
    radius: 20,
    color: Colors.GLOW_BLUE,
    offsetX: 0,
    offsetY: 0
  }
}

// ==================== 主题感知颜色 ====================
export type ThemeMode = 'light' | 'dark' | 'follow-system'

export class ThemeColors {
  static bg(isDark: boolean): string {
    return isDark ? Colors.BG_DARK : Colors.BG_LIGHT
  }
  static surface(isDark: boolean): string {
    return isDark ? Colors.SURFACE_DARK : Colors.SURFACE_LIGHT
  }
  static elevated(isDark: boolean): string {
    return isDark ? Colors.ELEVATED_DARK : Colors.ELEVATED_LIGHT
  }
  static divider(isDark: boolean): string {
    return isDark ? Colors.DIVIDER_DARK : Colors.DIVIDER_LIGHT
  }
  static textPrimary(isDark: boolean): string {
    return isDark ? Colors.TEXT_PRIMARY_DARK : Colors.TEXT_PRIMARY_LIGHT
  }
  static textSecondary(isDark: boolean): string {
    return isDark ? Colors.TEXT_SECONDARY_DARK : Colors.TEXT_SECONDARY_LIGHT
  }
  static textTertiary(isDark: boolean): string {
    return isDark ? Colors.TEXT_TERTIARY_DARK : Colors.TEXT_TERTIARY_LIGHT
  }
  static textDisabled(isDark: boolean): string {
    return isDark ? Colors.TEXT_DISABLED_DARK : Colors.TEXT_DISABLED_LIGHT
  }
  static cardShadow(isDark: boolean): string {
    return isDark ? '#1AFFFFFF' : '#1A000000'
  }
  static itemBg(isDark: boolean): string {
    return isDark ? '#2A2A2A' : '#F5F5F5'
  }
  static selectedBg(isDark: boolean): string {
    return isDark ? '#1A007DFF' : Colors.BRAND_PRIMARY + '10'
  }
  static glowBlue(isDark: boolean): string {
    return isDark ? '#4D007DFF' : Colors.GLOW_BLUE
  }
  static cardBg(isDark: boolean): string {
    if (isDark) return 'rgba(42, 42, 42, 0.7)'
    return 'rgba(255, 255, 255, 0.7)'
  }
  static cardBgOff(isDark: boolean): string {
    if (isDark) return 'rgba(38, 38, 38, 0.6)'
    return 'rgba(250, 250, 250, 0.6)'
  }
  static cardBgOffline(isDark: boolean): string {
    if (isDark) return 'rgba(50, 50, 50, 0.8)'
    return 'rgba(240, 240, 240, 0.8)'
  }
}

// ==================== 动画曲线 ====================
export class AnimationCurves {
  static readonly EASE_OUT = 'EaseOut'           // 进入动画
  static readonly EASE_IN = 'EaseIn'             // 退出动画
  static readonly FAST_OUT_SLOW_IN = 'FastOutSlowIn'  // 弹性反馈
  static readonly LINEAR = 'Linear'              // 线性
  static readonly SPRING = 'Spring'              // 弹性动画
}
