import router from '@ohos.router'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'

interface NotificationItem {
  id: string
  icon: string
  title: string
  content: string
  time: string
  type: string
  read: boolean
}

@Entry
@Component
struct NotificationPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State selectedTab: number = 0
  @State notifications: NotificationItem[] = []

  aboutToAppear(): void {
    this.notifications = [
      { id: '1', icon: '🔒', title: '门锁提醒', content: '前门已成功锁定', time: '2分钟前', type: 'security', read: false },
      { id: '2', icon: '📹', title: '移动检测', content: '摄像头检测到画面移动', time: '15分钟前', type: 'security', read: false },
      { id: '3', icon: '📡', title: '传感器触发', content: '门磁传感器检测到门窗开启', time: '1小时前', type: 'security', read: false },
      { id: '4', icon: '❄️', title: '空调已开启', content: '客厅空调已自动开启，设定温度26°C', time: '2小时前', type: 'device', read: true },
      { id: '5', icon: '🎬', title: '场景执行', content: '温馨回家场景已自动执行', time: '3小时前', type: 'scene', read: true },
      { id: '6', icon: '🔄', title: '固件更新', content: '智能门锁固件已更新至v2.1.0', time: '昨天', type: 'system', read: true },
      { id: '7', icon: '⚡', title: '能耗提醒', content: '今日能耗已达5kWh，注意节约用电', time: '昨天', type: 'device', read: true },
      { id: '8', icon: '💡', title: '灯泡离线', content: '卧室灯泡已离线，请检查网络连接', time: '2天前', type: 'device', read: true }
    ]
  }

  getFilteredNotifications(): NotificationItem[] {
    if (this.selectedTab === 0) return this.notifications
    if (this.selectedTab === 1) return this.notifications.filter(n => n.type === 'security')
    if (this.selectedTab === 2) return this.notifications.filter(n => n.type === 'device')
    return this.notifications.filter(n => n.type === 'system')
  }

  getUnreadCount(): number {
    return this.notifications.filter(n => !n.read).length
  }

  markAllRead(): void {
    this.notifications = this.notifications.map(n => {
      n.read = true
      return n
    })
  }

  build() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            router.back()
          })

        Text('消息通知')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('全部已读')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            this.markAllRead()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.LG, right: Spacing.LG })
      .backgroundColor(ThemeColors.surface(this.isDark))

      Column({ space: Spacing.MD }) {
        Row({ space: Spacing.SM }) {
          ForEach(['全部', '安全', '设备', '系统'], (tab: string, index: number) => {
            Column() {
              Text(tab)
                .fontSize(FontSize.CAPTION1)
                .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedTab === index ? Colors.BRAND_PRIMARY : ThemeColors.textSecondary(this.isDark))

              Row()
                .width(20)
                .height(3)
                .borderRadius(2)
                .backgroundColor(this.selectedTab === index ? Colors.BRAND_PRIMARY : 'transparent')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .padding({ top: Spacing.MD, bottom: Spacing.MD })
            .onClick(() => {
              this.selectedTab = index
            })
          })
        }
        .width('100%')
        .backgroundColor(ThemeColors.surface(this.isDark))

        if (this.getUnreadCount() > 0 && this.selectedTab === 0) {
          Text(this.getUnreadCount() + '条未读消息')
            .fontSize(FontSize.CAPTION1)
            .fontColor(ThemeColors.textTertiary(this.isDark))
            .width('100%')
            .padding({ left: Spacing.LG })
        }

        Scroll() {
          Column({ space: Spacing.SM }) {
            ForEach(this.getFilteredNotifications(), (item: NotificationItem) => {
              Row() {
                Text(item.icon)
                  .fontSize(28)
                  .margin({ right: Spacing.MD })

                Column({ space: 4 }) {
                  Row() {
                    Text(item.title)
                      .fontSize(FontSize.BODY1)
                      .fontWeight(item.read ? FontWeight.Normal : FontWeight.Bold)
                      .fontColor(ThemeColors.textPrimary(this.isDark))

                    if (!item.read) {
                      Circle()
                        .width(8)
                        .height(8)
                        .fill(Colors.ERROR)
                        .margin({ left: Spacing.XS })
                    }

                    Blank()

                    Text(item.time)
                      .fontSize(FontSize.CAPTION2)
                      .fontColor(ThemeColors.textTertiary(this.isDark))
                  }
                  .width('100%')

                  Text(item.content)
                    .fontSize(FontSize.CAPTION1)
                    .fontColor(ThemeColors.textSecondary(this.isDark))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(Spacing.LG)
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(item.read ? ThemeColors.surface(this.isDark) : ThemeColors.selectedBg(this.isDark))
            })
          }
          .padding({ left: Spacing.LG, right: Spacing.LG })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
