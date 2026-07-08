import { HomePage } from './HomePage'
import { DevicePage } from './DevicePage'
import { ScenePage } from './ScenePage'
import { AIChatPage } from './AIChatPage'
import { ProfilePage } from './ProfilePage'
import { StorePage } from './StorePage'
import { DeviceStore } from '../DeviceStore'
import { FloatingNavBar, NavItemModel } from '../components/FloatingNavBar'
import { ThemeColors } from '../common/DesignConstants'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @StorageLink('navToScene') @Watch('onNavToSceneChange') navToScene: boolean = false
  @StorageLink('navToDevice') @Watch('onNavToDeviceChange') navToDevice: boolean = false
  @StorageProp('isDarkMode') isDark: boolean = false
   
  private lastIndex: number = 0

  aboutToAppear(): void {
    DeviceStore.initialize()
    DeviceStore.applyThemeMode(AppStorage.get<string>('themeMode') || 'follow-system')
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
    Stack() {
      HomePage().visibility(this.currentIndex === 0 ? Visibility.Visible : Visibility.Hidden)
      DevicePage().visibility(this.currentIndex === 1 ? Visibility.Visible : Visibility.Hidden)
      ScenePage().visibility(this.currentIndex === 2 ? Visibility.Visible : Visibility.Hidden)
      StorePage().visibility(this.currentIndex === 3 ? Visibility.Visible : Visibility.Hidden)
      AIChatPage().visibility(this.currentIndex === 4 ? Visibility.Visible : Visibility.Hidden)
      ProfilePage().visibility(this.currentIndex === 5 ? Visibility.Visible : Visibility.Hidden)
    }
    .width('100%')
    .height('100%')
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
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}