/**
 * 设备详情页 - 亮度/色温调节 + 情景模式
 * 基于 HarmonyOS Design 规范实现
 */
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig, ThemeColors } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'
import { HaloSlider } from '../components/HaloSlider'
import { HaloToggle } from '../components/HaloToggle'

export interface DeviceDetailParams {
  id: string
  name: string
  icon: string
  room: string
}

export interface ModeItem {
  id: string
  name: string
  icon: string
  color: string
}

export interface TimerItemData {
  time: string
  action: string
  enabled: boolean
}

@Entry
@Component
export struct DeviceDetailPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State private deviceParams: DeviceDetailParams = {
    id: '',
    name: '设备详情',
    icon: '💡',
    room: '客厅'
  }
  @State private isOn: boolean = true
  @State private brightnessLevel: number = 80
  @State private colorTemp: number = 4000
  @State private selectedMode: string = 'normal'

  private readonly modes: ModeItem[] = [
    { id: 'normal', name: '日常', icon: '☀️', color: Colors.BRAND_PRIMARY },
    { id: 'reading', name: '阅读', icon: '📖', color: '#FFB800' },
    { id: 'relax', name: '休闲', icon: '🌙', color: '#8B5CF6' },
    { id: 'night', name: '夜灯', icon: '🌃', color: '#6B7280' }
  ]

  @State private timerList: TimerItemData[] = [
    { time: '07:00', action: '自动开启', enabled: true },
    { time: '22:00', action: '自动关闭', enabled: true }
  ]

  build() {
    Column() {
      this.NavigationBar()

      Scroll() {
        Column({ space: Spacing.XL }) {
          this.StatusCard()
          this.BrightnessSection()
          this.ColorTempSection()
          this.ModeSection()
          this.TimerSection()
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

  @Builder NavigationBar() {
    Row() {
      HaloButton({
        icon: '←',
        buttonSize: 'medium',
        type: 'ghost'
      })

      Blank()

      Text(this.deviceParams.name)
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))

      Blank()

      HaloButton({
        icon: '⚙️',
        buttonSize: 'medium',
        type: 'ghost'
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder StatusCard() {
    Column({ space: Spacing.LG }) {
      Row() {
        Column({ space: 8 }) {
          Text(this.deviceParams.icon)
            .fontSize(64)
            .opacity(this.isOn ? 1 : 0.5)

          Text(this.isOn ? '运行中' : '已关闭')
            .fontSize(FontSize.BODY2)
            .fontColor(this.isOn ? Colors.SUCCESS : ThemeColors.textSecondary(this.isDark))
        }

        Blank()

        Column({ space: 8 }) {
          HaloToggle({
            isOn: this.isOn,
            onChange: (value: boolean) => {
              this.isOn = value
            }
          })
        }
      }
      .width('100%')

      Row() {
        Text('📍')
          .fontSize(16)

        Text(this.deviceParams.room)
          .fontSize(FontSize.BODY2)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }
    }
    .width('100%')
    .padding(Spacing.XL)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: this.isOn ? 16 : 4,
      color: this.isOn ? ThemeColors.glowBlue(this.isDark) : ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder BrightnessSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('💡')
          .fontSize(20)

        Text('亮度')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }

      HaloSlider({
        value: this.brightnessLevel,
        min: 0,
        max: 100,
        step: 5,
        showValue: true,
        unit: '%',
        onChange: (value: number) => {
          this.brightnessLevel = value
        }
      })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder ColorTempSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('🎨')
          .fontSize(20)

        Text('色温')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }

      HaloSlider({
        value: this.colorTemp,
        min: 2700,
        max: 6500,
        step: 100,
        showValue: true,
        unit: 'K',
        onChange: (value: number) => {
          this.colorTemp = value
        }
      })

      Row({ space: Spacing.SM }) {
        Column()
          .width(40)
          .height(20)
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor('#FFA500')

        Column()
          .width('100%')
          .height(20)
          .borderRadius(BorderRadius.SMALL)
          .linearGradient({
            angle: 90,
            colors: [
              ['#FFA500', 0],
              ['#FFFFFF', 0.5],
              ['#87CEEB', 1]
            ]
          })

        Column()
          .width(40)
          .height(20)
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor('#87CEEB')
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder ModeSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('🎭')
          .fontSize(20)

        Text('情景模式')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width('100%')

      Grid() {
        ForEach(this.modes, (mode: ModeItem) => {
          GridItem() {
            Column({ space: 8 }) {
              Text(mode.icon)
                .fontSize(32)

              Text(mode.name)
                .fontSize(FontSize.CAPTION1)
                .fontColor(this.selectedMode === mode.id ? ThemeColors.textPrimary(this.isDark) : ThemeColors.textSecondary(this.isDark))
            }
            .width('100%')
            .height(80)
            .justifyContent(FlexAlign.Center)
            .borderRadius(BorderRadius.MEDIUM)
            .backgroundColor(this.selectedMode === mode.id ? mode.color + '20' : ThemeColors.itemBg(this.isDark))
            .borderWidth(this.selectedMode === mode.id ? 2 : 0)
            .borderColor(mode.color)
            .onClick(() => {
              this.selectedMode = mode.id
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(Spacing.SM)
      .columnsGap(Spacing.SM)
      .width('100%')
      .height(100)
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder TimerSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('⏰')
          .fontSize(20)

        Text('定时设置')
          .fontSize(FontSize.BODY1)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))

        Blank()

        HaloButton({
          label: '添加',
          buttonSize: 'small',
          type: 'outline'
        })
      }
      .width('100%')

      Column({ space: Spacing.SM }) {
        ForEach(this.timerList, (timer: TimerItemData, index: number) => {
          this.TimerItem(timer, index)
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  @Builder TimerItem(timer: TimerItemData, index: number) {
    Row() {
      Text(timer.time)
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))

      Text(timer.action)
        .fontSize(FontSize.BODY2)
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .margin({ left: Spacing.SM })

      Blank()

      HaloToggle({
        isOn: timer.enabled,
        onChange: (value: boolean) => {
          this.timerList[index] = { time: timer.time, action: timer.action, enabled: value }
        }
      })
    }
    .width('100%')
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(ThemeColors.itemBg(this.isDark))
  }
}
