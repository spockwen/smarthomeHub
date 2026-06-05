import { HomePage } from './HomePage'
import { DevicePage } from './DevicePage'
import { ScenePage } from './ScenePage'
import { AIChatPage } from './AIChatPage'
import { ProfilePage } from './ProfilePage'
import { DeviceStore } from '../DeviceStore'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0

  // 应用启动时初始化全局状态
  aboutToAppear(): void {
    DeviceStore.initialize()
  }

  build() {
    Tabs({
      barPosition: BarPosition.End
    }) {

      TabContent() {
        HomePage()
      }
      .tabBar('首页')

      TabContent() {
        DevicePage()
      }
      .tabBar('设备')

      TabContent() {
        ScenePage()
      }
      .tabBar('场景')

      TabContent() {
        AIChatPage()
      }
      .tabBar('AI')

      TabContent() {
        ProfilePage()
      }
      .tabBar('我的')

    }
  }
}
