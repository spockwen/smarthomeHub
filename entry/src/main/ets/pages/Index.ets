import { HomePage } from './HomePage'
import { DevicePage } from './DevicePage'
import { ScenePage } from './ScenePage'
import { AIChatPage } from './AIChatPage'
import { ProfilePage } from './ProfilePage'
import { StorePage } from './StorePage'
import { DeviceStore } from '../DeviceStore'
import { FloatingNavBar, NavItemModel } from '../components/FloatingNavBar'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0

  // 监听来自首页的导航请求
  @Watch('onNavToSceneChange') @StorageLink('navToScene') navToScene: boolean = false
  @Watch('onNavToDeviceChange') @StorageLink('navToDevice') navToDevice: boolean = false
  
  private lastIndex: number = 0

  aboutToAppear(): void {
    DeviceStore.initialize()
  }
  
  onNavToSceneChange(): void {
    if (this.navToScene) {
      this.currentIndex = 2
      this.navToScene = false
    }
  }
  
  onNavToDeviceChange(): void {
    if (this.navToDevice) {
      this.currentIndex = 1
      this.navToDevice = false
    }
  }
  
  // 监听导航状态变化
  indexChange(newIndex: number): void {
    if (this.currentIndex !== newIndex) {
      this.lastIndex = this.currentIndex
      this.currentIndex = newIndex
    }
  }

  private navItems: NavItemModel[] = [
    { title: '首页' },
    { title: '设备' },
    { title: '场景' },
    { title: '商城' },
    { title: 'AI' },
    { title: '我的' }
  ]

  @Builder
  pageContent() {
    if (this.currentIndex === 0) {
      HomePage()
    } else if (this.currentIndex === 1) {
      DevicePage()
    } else if (this.currentIndex === 2) {
      ScenePage()
    } else if (this.currentIndex === 3) {
      StorePage()
    } else if (this.currentIndex === 4) {
      AIChatPage()
    } else {
      ProfilePage()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      this.pageContent()

      FloatingNavBar({
        items: this.navItems,
        selectedIndex: this.currentIndex,
        onIndexChange: (index: number) => {
          this.currentIndex = index
        }
      })
      .position({ bottom: 16 })
      .padding({ left: 40, right: 40 })
    }
    .width('100%')
    .height('100%')
  }
}