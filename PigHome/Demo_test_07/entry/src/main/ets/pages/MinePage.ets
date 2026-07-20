// ============================================================
// 【我的】页面 - MinePage.ets
// 用户信息 + 全屋能耗仪表盘 + 用电概览 + 设置菜单列表
// ============================================================

import { KEYS, getOnlineDeviceCount } from '../service/DeviceStateService'

interface GaugeItem {
  icon: string
  label: string
  unit: string
  color: string
  bgColor: string
}

interface PowerItem {
  name: string
  percent: number
  color: string
}

interface MenuItem {
  id: string
  icon: string
  iconBg: string
  label: string
  danger?: boolean
}

const POWER_ITEMS: PowerItem[] = [
  { name: '空调', percent: 72, color: '#4080FF' },
  { name: '热水器', percent: 14, color: '#FF8C00' },
  { name: '照明', percent: 9,  color: '#52C41A' },
  { name: '其他',  percent: 5,  color: '#CCCCCC' }
]

const MENU_ITEMS: MenuItem[] = [
  { id: 'family',  icon: '👥', iconBg: '#EEF3FF', label: '家庭成员管理' },
  { id: 'notice',  icon: '🔔', iconBg: '#FFF7E6', label: '消息与提醒' },
  { id: 'privacy', icon: '🔒', iconBg: '#FFF1F0', label: '隐私与安全' },
  { id: 'devices', icon: '📱', iconBg: '#F0F2FF', label: '已连接设备' },
  { id: 'logout',  icon: '🚪', iconBg: '#FFF1F0', label: '退出登录', danger: true }
]

@Entry
@Component
export struct MinePage {
  @State totalKwh: number = 127.4
  @State savedPercent: number = 12
  @State estimatedFee: number = 89
  @StorageProp(KEYS.AC_TEMP) acTemp: number = 26
  @StorageProp(KEYS.DOOR_LOCKED) doorLocked: boolean = false

  // 仪表盘指标卡配置
  private gaugeCards: GaugeItem[] = [
    { icon: '🔌', label: '在线设备', unit: '/8',  color: '#007DFF', bgColor: '#F0F7FF' },
    { icon: '🌡️', label: '室内温度', unit: '°C',   color: '#FF6B35', bgColor: '#FFF5F0' },
    { icon: '⚡',  label: '当日用电', unit: 'kWh',  color: '#52C41A', bgColor: '#F0FFF0' },
    { icon: '🔒',  label: '安防状态', unit: '',     color: '#7C5CFC', bgColor: '#F5F0FF' },
  ]

  build() {
    Column() {

      // ======== 顶部标题 ========
      Row() {
        Text('我的')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Blank()
        Text('⚙️')
          .fontSize(22)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      Scroll() {
        Column({ space: 0 }) {

          // ======== 用户信息卡片 ========
          Row({ space: 14 }) {
            // 头像
            Text('王')
              .fontSize(24)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
              .width(60)
              .height(60)
              .textAlign(TextAlign.Center)
              .backgroundColor('#4080FF')
              .borderRadius(30)

            // 信息
            Column({ space: 4 }) {
              Text('王先生')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')

              Text('ID: 10086 · 管理员')
                .fontSize(12)
                .fontColor('#888888')

              Row({ space: 4 }) {
                Text('🏠')
                  .fontSize(12)
                Text('已绑定家庭')
                  .fontSize(12)
                  .fontColor('#888888')
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 16 })
          .alignItems(VerticalAlign.Center)

          // ======== 全屋能耗仪表盘 ========
          Column() {
            Text('📊 全屋能耗仪表盘')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .width('100%')
              .margin({ bottom: 14 })

            // 第 1 行：在线设备 + 室内温度
            Row({ space: 10 }) {
              this.GaugeCell(this.gaugeCards[0], `${getOnlineDeviceCount()}`, '/8')
              this.GaugeCell(this.gaugeCards[1], `${this.acTemp}`, '°C')
            }
            .width('100%')
            .margin({ bottom: 10 })

            // 第 2 行：当日用电 + 安防状态
            Row({ space: 10 }) {
              this.GaugeCell(this.gaugeCards[2], `${this.totalKwh}`, 'kWh')
              this.GaugeCell(this.gaugeCards[3], this.doorLocked ? '已布防' : '未布防', '')
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 14 })

          // ======== 用电概览卡片 ========
          Column({ space: 0 }) {
            Text('本月用电概览')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .width('100%')
              .margin({ bottom: 14 })

            // 三格数据
            Row() {
              // 用电量
              Column({ space: 4 }) {
                Text(`${this.totalKwh}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4080FF')
                Text('本月 kWh')
                  .fontSize(11)
                  .fontColor('#888888')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              // 环比
              Column({ space: 4 }) {
                Text(`↓ ${this.savedPercent}%`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#52C41A')
                Text('较上月')
                  .fontSize(11)
                  .fontColor('#888888')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              // 预估费用
              Column({ space: 4 }) {
                Text(`¥${this.estimatedFee}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF8C00')
                Text('预估费用')
                  .fontSize(11)
                  .fontColor('#888888')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .backgroundColor('#F8F8F8')
            .borderRadius(12)
            .padding(14)
            .margin({ bottom: 14 })

            // 用电分类进度条
            Column({ space: 12 }) {
              ForEach(POWER_ITEMS, (item: PowerItem) => {
                Row({ space: 10 }) {
                  Text(item.name)
                    .fontSize(13)
                    .fontColor('#444444')
                    .width(40)

                  // 进度条背景
                  Stack({ alignContent: Alignment.Start }) {
                    Row()
                      .width('100%')
                      .height(8)
                      .backgroundColor('#EEEEEE')
                      .borderRadius(4)

                    Row()
                      .width(`${item.percent}%`)
                      .height(8)
                      .backgroundColor(item.color)
                      .borderRadius(4)
                  }
                  .layoutWeight(1)

                  Text(`${item.percent}%`)
                    .fontSize(12)
                    .fontColor('#888888')
                    .width(36)
                    .textAlign(TextAlign.End)
                }
                .alignItems(VerticalAlign.Center)
              })
            }
          }
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ left: 20, right: 20, bottom: 12 })
          .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

          // ======== 菜单列表 ========
          Column({ space: 0 }) {
            ForEach(MENU_ITEMS, (item: MenuItem, index: number) => {
              Row() {
                // 图标
                Text(item.icon)
                  .fontSize(18)
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(item.iconBg)
                  .borderRadius(10)

                // 标签
                Text(item.label)
                  .fontSize(15)
                  .fontColor(item.danger ? '#FF4D4F' : '#1A1A1A')
                  .layoutWeight(1)
                  .margin({ left: 12 })

                // 箭头
                Text('›')
                  .fontSize(20)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .padding({ top: 14, bottom: 14 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                // 各菜单项点击逻辑（预留）
              })

              // 分割线（最后一项不加）
              if (index < MENU_ITEMS.length - 1) {
                Divider()
                  .color('#F5F5F5')
                  .margin({ left: 52 })
              }
            })
          }
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .margin({ left: 20, right: 20, bottom: 20 })
          .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

          Blank().height(20)
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  // ============================================================
  // 仪表盘指标卡组件
  // ============================================================
  @Builder
  GaugeCell(item: GaugeItem, value: string, suffix: string) {
    Column({ space: 6 }) {
      Text(item.icon)
        .fontSize(22)
        .lineHeight(26)

      Row({ space: 2 }) {
        Text(value)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.color)

        if (suffix.length > 0) {
          Text(suffix)
            .fontSize(12)
            .fontColor('#AAAAAA')
            .margin({ top: 6 })
        }
      }
      .alignItems(VerticalAlign.Center)
      .height(28)

      Text(item.label)
        .fontSize(12)
        .fontColor('#999999')
    }
    .layoutWeight(1)
    .aspectRatio(1.0)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(item.bgColor)
    .borderRadius(14)
    .padding(8)
  }
}
