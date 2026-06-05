/**
 * 个人中心页 - 用户信息 + 设置入口
 * 基于 HarmonyOS Design 规范实现
 */
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'

// 设置项数据模型
interface SettingItem {
  id: string
  icon: string
  title: string
  subtitle?: string
  showArrow: boolean
  badge?: string
}

@Component
export struct ProfilePage {
  // 用户信息
  @State private userName: string = '软件杯参赛队'
  @State private avatar: string = '👤'
  @State private familyCount: number = 1
  @State private deviceCount: number = 12
  @State private sceneCount: number = 5
  
  // 设置项列表
  private readonly settings: SettingItem[] = [
    { id: 'family', icon: '🏠', title: '家庭管理', subtitle: '默认家庭', showArrow: true },
    { id: 'devices', icon: '📱', title: '我的设备', subtitle: '12台设备', showArrow: true },
    { id: 'energy', icon: '📊', title: '能耗统计', subtitle: '今日 8.5kWh', showArrow: true, badge: 'NEW' },
    { id: 'security', icon: '🔐', title: '安全中心', subtitle: '设备状态：安全', showArrow: true },
    { id: 'notification', icon: '🔔', title: '消息通知', showArrow: true, badge: '3' },
    { id: 'voice', icon: '🎤', title: '语音助手', subtitle: '已启用', showArrow: true },
    { id: 'theme', icon: '🎨', title: '主题设置', showArrow: true },
    { id: 'help', icon: '❓', title: '帮助与反馈', showArrow: true },
    { id: 'about', icon: 'ℹ️', title: '关于', subtitle: 'v1.0.0', showArrow: true }
  ]
  
  build() {
    Column() {
      // 顶部用户卡片
      this.UserCard()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          // 快捷统计
          this.StatsSection()
          
          // 设置列表
          this.SettingsSection()
          
          // 底部信息
          this.FooterSection()
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
  
  // 用户卡片
  @Builder UserCard() {
    Column({ space: Spacing.LG }) {
      // 用户信息
      Row({ space: Spacing.LG }) {
        // 头像
        Column() {
          Text(this.avatar)
            .fontSize(48)
        }
        .width(80)
        .height(80)
        .borderRadius(BorderRadius.FULL)
        .backgroundColor(Colors.BRAND_PRIMARY + '20')
        .justifyContent(FlexAlign.Center)
        
        // 用户名和简介
        Column({ space: 8 }) {
          Text(this.userName)
            .fontSize(FontSize.TITLE2)
            .fontWeight(700)
            .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          
          Text('智能家居爱好者')
            .fontSize(FontSize.BODY2)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        // 编辑按钮
        HaloButton({
          icon: '✏️',
          buttonSize: 'small',
          type: 'ghost'
        })
      }
      .width('100%')
      
      // 家庭和设备统计
      Row({ space: Spacing.XL }) {
        this.StatItem('🏠', '家庭', this.familyCount.toString())
        this.StatItem('📱', '设备', this.deviceCount.toString())
        this.StatItem('🎬', '场景', this.sceneCount.toString())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .padding(Spacing.XL)
    .backgroundColor(Colors.BRAND_PRIMARY)
    .linearGradient({
      angle: 135,
      colors: [
        [Colors.BRAND_PRIMARY, 0],
        [Colors.BRAND_SECONDARY, 1]
      ]
    })
  }
  
  // 统计项
  @Builder StatItem(icon: string, label: string, value: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(24)
      
      Text(value)
        .fontSize(FontSize.TITLE2)
        .fontWeight(700)
        .fontColor('#FFFFFF')
      
      Text(label)
        .fontSize(FontSize.CAPTION1)
        .fontColor('#FFFFFF99')  // 60% 白色
    }
  }
  
  // 快捷统计
  @Builder StatsSection() {
    Row({ space: Spacing.SM }) {
      // 今日能耗
      this.QuickStatCard('⚡', '8.5', 'kWh', '今日能耗', Colors.WARNING)
      
      // 在线设备
      this.QuickStatCard('🔗', '12', '台', '在线设备', Colors.SUCCESS)
      
      // 场景执行
      this.QuickStatCard('🎬', '28', '次', '今日执行', Colors.BRAND_PRIMARY)
    }
    .width('100%')
    .margin({ top: Spacing.LG })
  }
  
  // 快捷统计卡片
  @Builder QuickStatCard(icon: string, value: string, unit: string, label: string, color: string) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(28)
      
      Row({ space: 2 }) {
        Text(value)
          .fontSize(FontSize.TITLE3)
          .fontWeight(700)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Text(unit)
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
      }
      
      Text(label)
        .fontSize(FontSize.CAPTION1)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
    }
    .width('32%')
    .padding(Spacing.MD)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
  
  // 设置列表
  @Builder SettingsSection() {
    Column({ space: 2 }) {
      ForEach(this.settings, (item: SettingItem, index: number) => {
        this.SettingItem(item, index === this.settings.length - 1)
      })
    }
    .width('100%')
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 设置项
  @Builder SettingItem(item: SettingItem, isLast: boolean) {
    Row() {
      // 图标
      Text(item.icon)
        .fontSize(24)
        .margin({ right: Spacing.MD })
      
      // 标题和副标题
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(FontSize.BODY1)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        if (item.subtitle) {
          Text(item.subtitle)
            .fontSize(FontSize.CAPTION1)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 徽章
      if (item.badge) {
        Text(item.badge)
          .fontSize(FontSize.CAPTION2)
          .fontColor('#FFFFFF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor(Colors.ERROR)
      }
      
      // 箭头
      if (item.showArrow) {
        Text('>')
          .fontSize(16)
          .fontColor(Colors.TEXT_TERTIARY_LIGHT)
          .margin({ left: Spacing.SM })
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .onClick(() => {
      this.handleSettingClick(item.id)
    })
  }
  
  // 底部信息
  @Builder FooterSection() {
    Column({ space: Spacing.SM }) {
      Text('鸿蒙智家 AI Hub')
        .fontSize(FontSize.CAPTION1)
        .fontColor(Colors.TEXT_TERTIARY_LIGHT)
      
      Text('v1.0.0 | OpenHarmony Edition')
        .fontSize(FontSize.CAPTION2)
        .fontColor(Colors.TEXT_TERTIARY_LIGHT)
    }
    .width('100%')
    .margin({ top: Spacing.XL })
  }
  
  // 处理设置项点击
  private handleSettingClick(id: string) {
    switch (id) {
      case 'family':
        AlertDialog.show({
          title: '家庭管理',
          message: '当前家庭：默认家庭\n成员数量：1\n该功能正在开发中'
        })
        break
      case 'devices':
        AlertDialog.show({
          title: '我的设备',
          message: '当前已接入设备：12台\n包括灯光、空调、门锁、窗帘、插座等设备'
        })
        break
      case 'energy':
        AlertDialog.show({
          title: '能耗统计',
          message: '今日能耗：8.5kWh\n本周能耗：62.3kWh\n本月能耗：245.8kWh'
        })
        break
      case 'security':
        AlertDialog.show({
          title: '安全中心',
          message: '传输加密：TLS\n数据加密：AES\n设备状态：安全'
        })
        break
      case 'about':
        AlertDialog.show({
          title: '鸿蒙智家 AI Hub',
          message: '基于 OpenHarmony 的 AI 全屋智能控制平台\n\n版本：v1.0.0\n\n软件杯参赛项目'
        })
        break
      default:
        AlertDialog.show({
          title: '提示',
          message: `${id} 功能开发中`
        })
    }
  }
}
