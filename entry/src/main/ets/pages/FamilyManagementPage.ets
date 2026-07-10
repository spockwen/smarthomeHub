import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import { DeviceStore } from '../DeviceStore'

interface FamilyMember {
  id: string
  name: string
  avatar: string
  role: string
  online: boolean
}

interface FamilyRoom {
  id: string
  name: string
  icon: string
  deviceCount: number
}

@Entry
@Component
struct FamilyManagementPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @StorageLink('onlineDevices') onlineDevices: number = 12
  @State currentFamily: string = '我的家'
  @State showAddMember: boolean = false
  @State newMemberName: string = ''

  private members: FamilyMember[] = [
    { id: '1', name: '我', avatar: '👤', role: '管理员', online: true },
    { id: '2', name: '家人A', avatar: '👩', role: '成员', online: true },
    { id: '3', name: '家人B', avatar: '👨', role: '成员', online: false }
  ]

  private rooms: FamilyRoom[] = [
    { id: 'living', name: '客厅', icon: '🛋️', deviceCount: 5 },
    { id: 'bedroom', name: '卧室', icon: '🛏️', deviceCount: 3 },
    { id: 'kitchen', name: '厨房', icon: '🍳', deviceCount: 2 },
    { id: 'bathroom', name: '卫生间', icon: '🚿', deviceCount: 1 },
    { id: 'study', name: '书房', icon: '📚', deviceCount: 1 }
  ]

  build() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            router.back()
          })

        Text('家庭管理')
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
            Text('当前家庭')
              .fontSize(FontSize.BODY2)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .width('100%')
              .padding({ left: Spacing.LG })

            Row() {
              Text('🏠')
                .fontSize(32)
                .margin({ right: Spacing.LG })

              Column({ space: 4 }) {
                Text(this.currentFamily)
                  .fontSize(FontSize.BODY1)
                  .fontWeight(600)
                  .fontColor(ThemeColors.textPrimary(this.isDark))

                Text(this.members.length + '位成员 · ' + this.rooms.length + '个房间 · ' + this.onlineDevices + '台设备')
                  .fontSize(FontSize.CAPTION1)
                  .fontColor(ThemeColors.textSecondary(this.isDark))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('✏️')
                .fontSize(20)
                .margin({ right: Spacing.MD })
            }
            .width('100%')
            .padding(Spacing.LG)
            .borderRadius(BorderRadius.LARGE)
            .backgroundColor(ThemeColors.surface(this.isDark))
            .shadow({ radius: 4, color: ThemeColors.cardShadow(this.isDark), offsetX: 0, offsetY: 2 })
          }

          Column({ space: Spacing.MD }) {
            Row() {
              Text('家庭成员')
                .fontSize(FontSize.BODY2)
                .fontColor(ThemeColors.textSecondary(this.isDark))

              Blank()

              Text('+ 邀请')
                .fontSize(FontSize.CAPTION1)
                .fontColor(Colors.BRAND_PRIMARY)
                .onClick(() => {
                  prompt.showToast({ message: '邀请链接已复制' })
                })
            }
            .width('100%')
            .padding({ left: Spacing.LG, right: Spacing.LG })

            Column({ space: Spacing.SM }) {
              ForEach(this.members, (member: FamilyMember) => {
                Row() {
                  Text(member.avatar)
                    .fontSize(32)
                    .margin({ right: Spacing.MD })

                  Column({ space: 4 }) {
                    Text(member.name)
                      .fontSize(FontSize.BODY1)
                      .fontColor(ThemeColors.textPrimary(this.isDark))

                    Text(member.role)
                      .fontSize(FontSize.CAPTION1)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Row() {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill(member.online ? Colors.SUCCESS : '#999999')
                      .margin({ right: Spacing.XS })

                    Text(member.online ? '在线' : '离线')
                      .fontSize(FontSize.CAPTION1)
                      .fontColor(member.online ? Colors.SUCCESS : ThemeColors.textTertiary(this.isDark))
                  }
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
            Row() {
              Text('房间管理')
                .fontSize(FontSize.BODY2)
                .fontColor(ThemeColors.textSecondary(this.isDark))

              Blank()

              Text('+ 添加')
                .fontSize(FontSize.CAPTION1)
                .fontColor(Colors.BRAND_PRIMARY)
                .onClick(() => {
                  prompt.showToast({ message: '添加房间功能开发中' })
                })
            }
            .width('100%')
            .padding({ left: Spacing.LG, right: Spacing.LG })

            Column({ space: Spacing.SM }) {
              ForEach(this.rooms, (room: FamilyRoom) => {
                Row() {
                  Text(room.icon)
                    .fontSize(28)
                    .margin({ right: Spacing.MD })

                  Column({ space: 4 }) {
                    Text(room.name)
                      .fontSize(FontSize.BODY1)
                      .fontColor(ThemeColors.textPrimary(this.isDark))

                    Text(room.deviceCount + '台设备')
                      .fontSize(FontSize.CAPTION1)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text('>')
                    .fontSize(16)
                    .fontColor(ThemeColors.textTertiary(this.isDark))
                }
                .width('100%')
                .padding(Spacing.LG)
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(ThemeColors.surface(this.isDark))
              })
            }
            .padding({ left: Spacing.LG, right: Spacing.LG })
          }

          Row() {
            Text('删除家庭')
              .fontSize(FontSize.BODY1)
              .fontColor(Colors.ERROR)
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .borderRadius(BorderRadius.LARGE)
          .backgroundColor(ThemeColors.surface(this.isDark))
          .margin({ top: Spacing.SM })
          .onClick(() => {
            AlertDialog.show({
              title: '确认删除',
              message: '删除后无法恢复，是否确认删除该家庭？',
              primaryButton: {
                value: '取消',
                action: () => {}
              },
              secondaryButton: {
                value: '删除',
                action: () => {
                  prompt.showToast({ message: '家庭已删除' })
                  router.back()
                }
              }
            })
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
