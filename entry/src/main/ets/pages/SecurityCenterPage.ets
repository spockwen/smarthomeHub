import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'

interface SecurityItem {
  id: string
  icon: string
  title: string
  status: string
  statusColor: string
  description: string
}

interface SecurityLog {
  time: string
  event: string
  level: string
}

@Entry
@Component
struct SecurityCenterPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @StorageLink('doorLocked') doorLocked: boolean = true
  @StorageLink('cameraOn') cameraOn: boolean = true
  @StorageLink('doorSensorOn') doorSensorOn: boolean = true

  private securityItems: SecurityItem[] = [
    { id: 'encrypt', icon: '🔒', title: '传输加密', status: '已启用', statusColor: Colors.SUCCESS, description: '所有数据传输采用TLS 1.3加密' },
    { id: 'data', icon: '🛡️', title: '数据加密', status: '已启用', statusColor: Colors.SUCCESS, description: '本地数据采用AES-256加密存储' },
    { id: 'auth', icon: '🔑', title: '身份认证', status: '已启用', statusColor: Colors.SUCCESS, description: '双因素身份验证保护账户安全' },
    { id: 'firewall', icon: '🧱', title: '网络防火墙', status: '已启用', statusColor: Colors.SUCCESS, description: '智能防御异常网络访问' },
    { id: 'update', icon: '🔄', title: '固件更新', status: '最新', statusColor: Colors.SUCCESS, description: '所有设备固件已是最新版本' },
    { id: 'door', icon: '🔐', title: '门锁状态', status: '已锁定', statusColor: Colors.SUCCESS, description: '前门智能门锁当前状态' },
    { id: 'camera', icon: '📹', title: '监控状态', status: '运行中', statusColor: Colors.SUCCESS, description: '摄像头正在正常工作' },
    { id: 'sensor', icon: '📡', title: '门磁传感器', status: '正常', statusColor: Colors.SUCCESS, description: '门窗传感器工作正常' }
  ]

  private securityLogs: SecurityLog[] = [
    { time: '14:32', event: '前门已锁定', level: 'info' },
    { time: '12:15', event: '摄像头检测到移动', level: 'warning' },
    { time: '09:30', event: '门磁传感器触发', level: 'info' },
    { time: '08:00', event: '安防系统自检完成', level: 'info' },
    { time: '昨日 23:45', event: '异常网络访问已拦截', level: 'danger' },
    { time: '昨日 18:20', event: '固件更新完成', level: 'info' }
  ]

  private getLevelColor(level: string): string {
    if (level === 'danger') return Colors.ERROR
    if (level === 'warning') return Colors.WARNING
    return ThemeColors.textTertiary(this.isDark)
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

        Text('安全中心')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('  ')
          .fontSize(FontSize.BODY2)
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.LG, right: Spacing.LG })
      .backgroundColor(ThemeColors.surface(this.isDark))

      Scroll() {
        Column({ space: Spacing.LG }) {
          Column({ space: Spacing.MD }) {
            Row() {
              Text('✅')
                .fontSize(48)

              Column({ space: 4 }) {
                Text('设备状态：安全')
                  .fontSize(FontSize.TITLE3)
                  .fontWeight(700)
                  .fontColor(Colors.SUCCESS)

                Text('所有安全功能运行正常')
                  .fontSize(FontSize.CAPTION1)
                  .fontColor(ThemeColors.textSecondary(this.isDark))
              }
              .margin({ left: Spacing.MD })
            }
            .width('100%')
            .padding(Spacing.XL)
            .borderRadius(BorderRadius.LARGE)
            .backgroundColor(Colors.SUCCESS + '15')
            .justifyContent(FlexAlign.Center)
          }
          .padding({ left: Spacing.LG, right: Spacing.LG })

          Column({ space: Spacing.MD }) {
            Text('安全项目')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: Spacing.SM }) {
              ForEach(this.securityItems, (item: SecurityItem) => {
                Row() {
                  Text(item.icon)
                    .fontSize(28)
                    .margin({ right: Spacing.MD })

                  Column({ space: 4 }) {
                    Text(item.title)
                      .fontSize(FontSize.BODY1)
                      .fontColor(ThemeColors.textPrimary(this.isDark))

                    Text(item.description)
                      .fontSize(FontSize.CAPTION1)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(item.status)
                    .fontSize(FontSize.CAPTION1)
                    .fontColor(item.statusColor)
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(12)
                    .backgroundColor(item.statusColor + '15')
                }
                .width('100%')
                .padding(Spacing.LG)
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(ThemeColors.surface(this.isDark))
              })
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Column({ space: Spacing.MD }) {
            Text('安全日志')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Column({ space: Spacing.SM }) {
              ForEach(this.securityLogs, (log: SecurityLog) => {
                Row() {
                  Column() {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill(this.getLevelColor(log.level))
                  }
                  .width(20)
                  .justifyContent(FlexAlign.Center)

                  Text(log.event)
                    .fontSize(FontSize.BODY2)
                    .fontColor(ThemeColors.textPrimary(this.isDark))
                    .layoutWeight(1)

                  Text(log.time)
                    .fontSize(FontSize.CAPTION1)
                    .fontColor(ThemeColors.textTertiary(this.isDark))
                }
                .width('100%')
                .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(ThemeColors.surface(this.isDark))
              })
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Row() {
            Text('一键安全检查')
              .fontSize(FontSize.BODY1)
              .fontColor('#FFFFFF')
              .fontWeight(600)
          }
          .width('90%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .borderRadius(24)
          .backgroundColor(Colors.BRAND_PRIMARY)
          .margin({ left: '5%' })
          .onClick(() => {
            prompt.showToast({ message: '安全检查完成，一切正常' })
          })
        }
        .width('100%')
        .padding({ top: Spacing.LG, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
