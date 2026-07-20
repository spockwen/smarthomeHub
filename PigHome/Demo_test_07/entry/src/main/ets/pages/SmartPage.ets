// ============================================================
// 【智能】页面 - SmartPage.ets
// 场景卡片 + 自动化开关列表
// 所有卡片 UI 统一由 SceneCard.ets 维护
// ============================================================

import { SceneItem, AutoItem, SceneCard, AutoCard, SceneModeCard } from '../components/SceneCard'
import { sendSceneCommand } from '../service/MqttService'
import { executeScene } from '../service/DeviceStateService'

const INIT_SCENES: SceneItem[] = [
  {
    id: 'home',
    name: '回家模式',
    desc: '打开灯光、空调、净化器',
    icon: '🏠',
    color: '#FF6B35',
    tags: ['客厅灯→开', '空调→26℃', '净化器→开', '窗帘→开 80%']
  },
  {
    id: 'leave',
    name: '离家模式',
    desc: '关闭所有灯光与空调',
    icon: '🍌',
    color: '#FFB800',
    tags: ['全部灯→关', '空调→关', '窗帘→关', '门锁→锁定']
  },
  {
    id: 'movie',
    name: '观影模式',
    desc: '灯光调暗，投影仪开启',
    icon: '🎬',
    color: '#7C5CFC',
    tags: ['客厅灯→20%', '投影仪→开', '窗帘→关']
  }
]

const INIT_AUTOS: AutoItem[] = [
  {
    id: 'auto_leave',
    name: '离家自动关灯',
    desc: '门锁锁定且无人移动时，关闭全屋灯光与空调',
    icon: '🚪',
    color: '#FF4D4F',
    enabled: true,
    statusText: '运行中'
  },
  {
    id: 'auto_home',
    name: '回家自动开灯',
    desc: '门锁解锁时，开启客厅灯光并调到舒适亮度',
    icon: '🏠',
    color: '#52C41A',
    enabled: true,
    statusText: '运行中'
  },
  {
    id: 'auto_curtain',
    name: '早晨窗帘开启',
    desc: '每天 07:30 自动打开卧室窗帘至 80%',
    icon: '☀️',
    color: '#FF7A00',
    enabled: false,
    statusText: '已关闭'
  }
]

@Entry
@Component
export struct SmartPage {
  @State scenes: SceneItem[] = INIT_SCENES
  @State autos: AutoItem[] = INIT_AUTOS

  toggleAuto(id: string) {
    this.autos = this.autos.map((a: AutoItem) => {
      if (a.id === id) {
        const next = !a.enabled
        return {
          id: a.id, name: a.name, desc: a.desc,
          icon: a.icon, color: a.color,
          enabled: next,
          statusText: next ? '运行中' : '已关闭'
        } as AutoItem
      }
      return a
    })
  }

  build() {
    Column() {

      // ======== 顶部标题 ========
      Row() {
        Column() {
          Text('智能')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Text('场景 & 自动化')
            .fontSize(13)
            .fontColor('#888888')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

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
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })

      Scroll() {
        Column({ space: 0 }) {

          // ======== 场景区块 ========
          Text('场景')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .padding({ left: 20, bottom: 10 })

          // ======== 场景模式卡片（统一使用 SceneModeCard 组件）=======
          SceneModeCard({
            icon: '🏠',
            name: '回家模式',
            color: '#FF6B35',
            tags: ['客厅灯→开', '空调→26℃', '净化器→开', '窗帘→开 80%'],
            onCardClick: () => {
              executeScene('回家模式')
              sendSceneCommand('回家模式')
            }
          })
          SceneModeCard({
            icon: '🍌',
            name: '离家模式',
            color: '#FFB800',
            tags: ['全部灯→关', '空调→关', '窗帘→关', '门锁→锁定'],
            onCardClick: () => {
              executeScene('离家模式')
              sendSceneCommand('离家模式')
            }
          })
          SceneModeCard({
            icon: '🎬',
            name: '观影模式',
            color: '#7C5CFC',
            tags: ['客厅灯→20%', '投影仪→开', '窗帘→关'],
            onCardClick: () => {
              executeScene('观影模式')
              sendSceneCommand('观影模式')
            }
          })

          // 添加场景按钮
          Text('+ 添加场景')
            .fontSize(15)
            .fontColor('#4080FF')
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 6, bottom: 16 })

          // 分割线
          Divider()
            .color('#F0F0F0')
            .margin({ left: 20, right: 20, bottom: 16 })

          // ======== 自动化区块 ========
          Text('自动化')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .padding({ left: 20, bottom: 10 })

          ForEach(this.autos, (auto: AutoItem) => {
            AutoCard({
              auto: auto,
              onToggle: (id: string) => { this.toggleAuto(id) }
            })
          })

          // 添加新自动化按钮
          Text('+ 添加新自动化')
            .fontSize(15)
            .fontColor('#4080FF')
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 6, bottom: 16 })

          // 底部安全距离
          Blank().height(20)
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}
