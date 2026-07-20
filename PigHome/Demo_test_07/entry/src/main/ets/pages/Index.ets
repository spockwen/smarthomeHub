// ============================================================
// 主入口 - Index.ets
// 底部 Tab 导航 + 5页面整合
// 替换 DevEco Studio 默认的 Hello World 页面
// ============================================================
//
// 【使用方法】
// 1. 将本文件内容替换 entry/src/main/ets/pages/Index.ets
// 2. 将 HomePage / SmartPage / AIPage / StorePage / MinePage
//    也放到同一个 pages 目录下
// 3. 在 main_pages.json 中注册所有页面路径
// ============================================================

import { HomePage }  from './HomePage'
import { SmartPage } from './SmartPage'
import { AIPage }    from './AIPage'
import { StorePage } from './StorePage'
import { MinePage }  from './MinePage'
import { initDeviceState } from '../service/DeviceStateService'
import { connectMqtt, disconnectMqtt, setConnectionCallback } from '../service/MqttService'

// Tab 配置
interface TabConfig {
  label: string
  icon: string
  activeIcon: string
}

const TAB_LIST: TabConfig[] = [
  { label: '家庭', icon: '🏠', activeIcon: '🏠' },
  { label: '智能', icon: '✨', activeIcon: '✨' },
  { label: 'AI',   icon: '🤖', activeIcon: '🤖' },
  { label: '商城', icon: '🛒', activeIcon: '🛒' },
  { label: '我的', icon: '👤', activeIcon: '👤' }
]

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State mqttConnected: boolean = false
  private tabController: TabsController = new TabsController()

  aboutToAppear() {
    initDeviceState(getContext())

    setConnectionCallback((connected: boolean) => {
      this.mqttConnected = connected
    })

    connectMqtt()
  }

  aboutToDisappear() {
    disconnectMqtt()
  }

  build() {
    Column() {
      // ======== MQTT 状态提示条 ========
      if (!this.mqttConnected) {
        Row() {
          Text('⚠️ MQTT 未连接，设备控制仅本地生效')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(28)
        .backgroundColor('#FF9800')
        .justifyContent(FlexAlign.Center)
      }

      // ======== 页面内容区域（占满剩余空间） ========
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentTab,
        controller: this.tabController
      }) {
        // ---- 家庭 Tab ----
        TabContent() {
          HomePage()
        }

        // ---- 智能 Tab ----
        TabContent() {
          SmartPage()
        }

        // ---- AI Tab ----
        TabContent() {
          AIPage()
        }

        // ---- 商城 Tab ----
        TabContent() {
          StorePage()
        }

        // ---- 我的 Tab ----
        TabContent() {
          MinePage()
        }
      }
      .layoutWeight(1)
      .barHeight(0)                    // 隐藏系统默认TabBar，自定义底部导航
      .onChange((index: number) => {
        this.currentTab = index
      })

      // ======== 自定义底部导航栏 ========
      Row() {
        ForEach(TAB_LIST, (tab: TabConfig, index: number) => {
          Column({ space: 3 }) {
            // 图标
            Text(this.currentTab === index ? tab.activeIcon : tab.icon)
              .fontSize(22)

            // 标签文字
            Text(tab.label)
              .fontSize(10)
              .fontColor(this.currentTab === index ? '#4080FF' : '#999999')
              .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 8, bottom: 8 })
          .onClick(() => {
            this.currentTab = index
            this.tabController.changeIndex(index)
          })
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 0.5 }, color: '#EEEEEE' })
    }
    .width('100%')
    .height('100%')
  }
}
