// ============================================================
// 【家庭】页面 - HomePage.ets
// ============================================================

import { DeviceCard } from '../components/DeviceCard'
import { sendToggleCommand, sendAdjustCommand } from '../service/MqttService'
import {
  ROOMS,
  getOnlineDeviceCount,
  getDevicesByRoom,
  getDeviceMeta
} from '../service/DeviceStateService'

// 判断某设备是否应显示（根据房间筛选）
function isDeviceVisible(deviceName: string, selectedRoom: string): boolean {
  if (selectedRoom === '全部') return true
  const meta = getDeviceMeta(deviceName)
  return meta !== undefined && meta.room === selectedRoom
}

// ============================================================
// 【家庭】主页面
// ============================================================
@Entry
@Component
export struct HomePage {
  @State selectedRoom: string = '全部'

  // ---- 各设备开关状态（通过 AppStorage 与 AI 页面共享） ----
  @StorageLink('isLightOn') isLightOn: boolean = true
  @StorageLink('isStudyLightOn') isStudyLightOn: boolean = true
  @StorageLink('studyLightLevel') studyLightLevel: number = 100
  @StorageLink('isRangeHoodOn') isRangeHoodOn: boolean = true
  @StorageLink('isPurifierOn') isPurifierOn: boolean = true
  @StorageLink('isACOn') isACOn: boolean = true
  @StorageLink('acTemp') acTemp: number = 24
  @StorageLink('isCurtainOn') isCurtainOn: boolean = true
  @StorageLink('curtainLevel') curtainLevel: number = 100
  @StorageLink('isProjectorOn') isProjectorOn: boolean = false
  @StorageLink('isDoorLocked') isDoorLocked: boolean = true

  build() {
    Column() {

      // ======== 顶部标题栏（家庭信息 + 在线设备数量） ========
      Row() {
        Column() {
          Text('我家')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Text('在线设备 · ' + getOnlineDeviceCount())
            .fontSize(13)
            .fontColor('#888888')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 右上角按钮
        Text('+')
          .fontSize(24)
          .fontColor('#444444')
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F0F0F0')
          .borderRadius(10)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      // ======== 房间筛选 Tab ========
      Scroll() {
        Row({ space: 8 }) {
          ForEach(ROOMS, (room: string) => {
            Text(room)
              .fontSize(14)
              .fontWeight(this.selectedRoom === room ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.selectedRoom === room ? '#FFFFFF' : '#666666')
              .backgroundColor(this.selectedRoom === room ? '#4080FF' : 'transparent')
              .borderRadius(20)
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .onClick(() => { this.selectedRoom = room })
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 12 })
      }

      // ======== 分隔线 ========
      Divider()
        .width('100%')
        .height(2)
        .color('#D0D0D0')

      // ======== 主要功能区 ========
      Column({ space: 10 }) {
        // ┌───────────────────────────────────────────────────┐
        // │  左列 col1~2（154vp）     │  右列 col3~4（154vp） │
        // │ ┌──────┐┌──────┐          │ ┌──────────────────┐ │
        // │ │ 💡   ││ 🍳   │          │ │ ❄️  空调         │ │
        // │ │客厅主灯││油烟机│          │ │  2×2 =154×154   │ │
        // │ ├──────┤├──────┤          │ │                  │ │
        // │ │ 💡   ││ 💨   │          │ │                  │ │
        // │ │书房灯││净化器│          │ ├──────────────────┤ │
        // │ │72×154││72×154│          │ │ 🪟 电动窗帘      │ │
        // │ │      ││AQI12 │          │ │  2×1 =154×72     │ │
        // │ └──────┘└──────┘          │ └──────────────────┘ │
        // └───────────────────────────────────────────────────┘
        Row({ space: 10 }) {
          // ========== 左列（col1 + col2 合并区域） ==========
          Column({ space: 10 }) {
            // ---- 第1行：客厅主灯 + 油烟机（各 72×72） ----
            Row({ space: 10 }) {
              if (isDeviceVisible('客厅主灯', this.selectedRoom)) {
                DeviceCard({
                  icon: '💡',
                  name: '客厅主灯',
                  statusText: this.isLightOn ? '100%' : '已关闭',
                  isOn: this.isLightOn,
                  onCardClick: () => {
                    this.isLightOn = !this.isLightOn
                    sendToggleCommand('客厅主灯', this.isLightOn)
                  }
                })
              }
              if (isDeviceVisible('油烟机', this.selectedRoom)) {
                DeviceCard({
                  icon: '🍳',
                  name: '油烟机',
                  statusText: this.isRangeHoodOn ? '运行中' : '已关闭',
                  isOn: this.isRangeHoodOn,
                  onCardClick: () => {
                    this.isRangeHoodOn = !this.isRangeHoodOn
                    sendToggleCommand('油烟机', this.isRangeHoodOn)
                  }
                })
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)

            // ---- 第2+3行：书房灯（竖放亮度） + 空气净化器（竖卡 72×154） ----
            Row({ space: 10 }) {
              if (isDeviceVisible('书房灯', this.selectedRoom)) {
                DeviceCard({
                  isTallDevice: true,
                  icon: '💡',
                  name: '书房灯',
                  isOn: this.isStudyLightOn,
                  lightLevel: this.studyLightLevel,
                  onCardClick: () => {
                    this.isStudyLightOn = !this.isStudyLightOn
                    sendToggleCommand('书房灯', this.isStudyLightOn)
                  },
                  onBrightnessChange: (val: number) => {
                    this.studyLightLevel = val
                    sendAdjustCommand('书房灯', val)
                  }
                })
              }
              if (isDeviceVisible('空气净化器', this.selectedRoom)) {
                DeviceCard({
                  spanRows: 2,
                  icon: '💨',
                  name: '空气净化器',
                  statusText: this.isPurifierOn ? 'AQI 12 优' : '已关闭',
                  isOn: this.isPurifierOn,
                  onCardClick: () => {
                    this.isPurifierOn = !this.isPurifierOn
                    sendToggleCommand('空气净化器', this.isPurifierOn)
                  }
                })
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
          }
          .width(154)    // = 72 + 10 + 72

          // ========== 右列（col3 + col4 合并区域） ==========
          Column({ space: 10 }) {
            // ---- 第1+2行：空调（大块 2×2 = 154×154，含温度拖动条 + 模式文本） ----
            if (isDeviceVisible('空调', this.selectedRoom)) {
              DeviceCard({
                spanColumns: 2,
                spanRows: 2,
                icon: '❄️',
                name: '空调',
                isOn: this.isACOn,
                showTemperatureSlider: true,
                temperature: this.acTemp,
                acMode: '制冷 · 主卧',
                onCardClick: () => {
                    this.isACOn = !this.isACOn
                    sendToggleCommand('空调', this.isACOn)
                  },
                  onTemperatureChange: (val: number) => {
                    this.acTemp = val
                    sendAdjustCommand('空调', val)
                  }
              })
            }

            // ---- 第3行：电动窗帘（横卡 2×1 = 154×72，含开合拖动条） ----
            if (isDeviceVisible('电动窗帘', this.selectedRoom)) {
              DeviceCard({
                isHorizontalDevice: true,
                spanColumns: 2,
                spanRows: 1,
                icon: '🪟',
                name: '电动窗帘',
                isOn: this.isCurtainOn,
                curtainLevel: this.curtainLevel,
                onCardClick: () => {
                    this.isCurtainOn = !this.isCurtainOn
                    sendToggleCommand('电动窗帘', this.isCurtainOn)
                  },
                  onCurtainChange: (val: number) => {
                    this.curtainLevel = val
                    sendAdjustCommand('电动窗帘', val)
                  }
              })
            }
          }
          .width(154)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // ======== 第4行：投影仪 + 智能门锁 + 2个空占位 ========
        Row({ space: 10 }) {
          if (isDeviceVisible('投影仪', this.selectedRoom)) {
            // 投影仪（参考油烟机，1×1）
            DeviceCard({
              icon: '🎥',
              name: '投影仪',
              statusText: this.isProjectorOn ? '运行中' : '已关闭',
              isOn: this.isProjectorOn,
              onCardClick: () => {
                    this.isProjectorOn = !this.isProjectorOn
                    sendToggleCommand('投影仪', this.isProjectorOn)
                  }
            })
          }
          if (isDeviceVisible('智能门锁', this.selectedRoom)) {
            // 智能门锁（1×1）
            DeviceCard({
              icon: '🔒',
              name: '智能门锁',
              statusText: this.isDoorLocked ? '已锁定' : '已解锁',
              isOn: !this.isDoorLocked,
              badgeText: '已解锁',
              badgeColor: '#7ED167',
              badgeTextOff: '已锁定',
              badgeColorOff: '#E74C3C',
              onCardClick: () => {
                    this.isDoorLocked = !this.isDoorLocked
                    sendToggleCommand('智能门锁', !this.isDoorLocked)
                  }
            })
          }
          DeviceCard({ isEmpty: true })
          DeviceCard({ isEmpty: true })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .padding({ left: 1, right: 1, top: 8 })
      .backgroundColor('#F2F2F7')
      .layoutWeight(1)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
