import { Colors, FontSize, Spacing, BorderRadius, GlowConfig, ThemeColors } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'
import router from '@ohos.router'

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
  @StorageProp('isDarkMode') isDark: boolean = false

  @State private userName: string = '软件杯参赛队'
  @State private avatar: string = '👤'
  @State private familyCount: number = 1
  @State private deviceCount: number = 12
  @State private sceneCount: number = 5

  private readonly settings: SettingItem[] = [
    { id: 'family', icon: '🏠', title: '家庭管理', subtitle: '默认家庭', showArrow: true },
    { id: 'devices', icon: '📱', title: '我的设备', subtitle: '12台设备', showArrow: true },
    { id: 'store', icon: '🛒', title: '商品管理', subtitle: '智能设备商城', showArrow: true },
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
      this.UserCard()

      Scroll() {
        Column({ space: Spacing.LG }) {
          this.StatsSection()
          this.SettingsSection()
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
    .backgroundColor(ThemeColors.bg(this.isDark))
  }

  @Builder UserCard() {
    Column({ space: Spacing.LG }) {
      Row({ space: Spacing.LG }) {
        Column() {
          Text(this.avatar)
            .fontSize(48)
        }
        .width(80)
        .height(80)
        .borderRadius(BorderRadius.FULL)
        .backgroundColor(Colors.BRAND_PRIMARY + '20')
        .justifyContent(FlexAlign.Center)

        Column({ space: 8 }) {
          Text(this.userName)
            .fontSize(FontSize.TITLE2)
            .fontWeight(700)
            .fontColor(ThemeColors.textPrimary(this.isDark))

          Text('智能家居爱好者')
            .fontSize(FontSize.BODY2)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        HaloButton({
          icon: '✏️',
          buttonSize: 'small',
          type: 'ghost'
        })
      }
      .width('100%')

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
        .fontColor('#FFFFFF99')
    }
  }

  @Builder StatsSection() {
    Row({ space: Spacing.SM }) {
      this.QuickStatCard('⚡', '8.5', 'kWh', '今日能耗', Colors.WARNING)
      this.QuickStatCard('🔗', '12', '台', '在线设备', Colors.SUCCESS)
      this.QuickStatCard('🎬', '28', '次', '今日执行', Colors.BRAND_PRIMARY)
    }
    .width('100%')
    .margin({ top: Spacing.LG })
  }

  @Builder QuickStatCard(icon: string, value: string, unit: string, label: string, color: string) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(28)

      Row({ space: 2 }) {
        Text(value)
          .fontSize(FontSize.TITLE3)
          .fontWeight(700)
          .fontColor(ThemeColors.textPrimary(this.isDark))

        Text(unit)
          .fontSize(FontSize.CAPTION1)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }

      Text(label)
        .fontSize(FontSize.CAPTION1)
        .fontColor(ThemeColors.textSecondary(this.isDark))
    }
    .width('32%')
    .padding(Spacing.MD)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: 4,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder SettingsSection() {
    Column({ space: 2 }) {
      ForEach(this.settings, (item: SettingItem, index: number) => {
        this.SettingItem(item, index === this.settings.length - 1)
      })
    }
    .width('100%')
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder SettingItem(item: SettingItem, isLast: boolean) {
    Row() {
      Text(item.icon)
        .fontSize(24)
        .margin({ right: Spacing.MD })

      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(FontSize.BODY1)
          .fontColor(ThemeColors.textPrimary(this.isDark))

        if (item.subtitle) {
          Text(item.subtitle)
            .fontSize(FontSize.CAPTION1)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (item.badge) {
        Text(item.badge)
          .fontSize(FontSize.CAPTION2)
          .fontColor('#FFFFFF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor(Colors.ERROR)
      }

      if (item.showArrow) {
        Text('>')
          .fontSize(16)
          .fontColor(ThemeColors.textTertiary(this.isDark))
          .margin({ left: Spacing.SM })
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .onClick(() => {
      this.handleSettingClick(item.id)
    })
  }

  @Builder FooterSection() {
    Column({ space: Spacing.SM }) {
      Text('鸿蒙智家 AI Hub')
        .fontSize(FontSize.CAPTION1)
        .fontColor(ThemeColors.textTertiary(this.isDark))

      Text('v1.0.0 | OpenHarmony Edition')
        .fontSize(FontSize.CAPTION2)
        .fontColor(ThemeColors.textTertiary(this.isDark))
    }
    .width('100%')
    .margin({ top: Spacing.XL })
  }

  private handleSettingClick(id: string) {
    switch (id) {
      case 'theme':
        router.pushUrl({ url: 'pages/ThemeSettingsPage' })
        break
      case 'store':
        router.pushUrl({ url: 'pages/StorePage' })
        break
      default:
        AlertDialog.show({
          title: id === 'family' ? '家庭管理' :
                 id === 'devices' ? '我的设备' :
                 id === 'energy' ? '能耗统计' :
                 id === 'security' ? '安全中心' :
                 id === 'about' ? '鸿蒙智家 AI Hub' : '提示',
          message: id === 'family' ? '当前家庭：默认家庭\n成员数量：1\n该功能正在开发中' :
                   id === 'devices' ? '当前已接入设备：12台\n包括灯光、空调、门锁、窗帘、插座等设备' :
                   id === 'energy' ? '今日能耗：8.5kWh\n本周能耗：62.3kWh\n本月能耗：245.8kWh' :
                   id === 'security' ? '传输加密：TLS\n数据加密：AES\n设备状态：安全' :
                   id === 'about' ? '基于 OpenHarmony 的 AI 全屋智能控制平台\n\n版本：v1.0.0\n\n软件杯参赛项目' :
                   `${id} 功能开发中`
        })
    }
  }
}
