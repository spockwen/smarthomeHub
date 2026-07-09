/**
 * 设备管理页 - 设备列表 + 分类筛选
 * 基于 HarmonyOS Design 规范实现
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import { DeviceCard, DeviceModel } from '../components/DeviceCard'
import router from '@ohos.router'

// 设备分类
type DeviceCategory = 'all' | 'light' | 'climate' | 'security' | 'appliance'

// 分类项接口
interface CategoryItem {
  id: string
  name: string
  icon: string
}

@Component
export struct DevicePage {
  // 全局状态
  @StorageLink('lightOn') lightOn: boolean = true
  @StorageLink('bedroomLightOn') bedroomLightOn: boolean = false
  @StorageLink('kitchenLightOn') kitchenLightOn: boolean = true
  @StorageLink('airOn') airOn: boolean = false
  @StorageLink('heaterOn') heaterOn: boolean = false
  @StorageLink('doorLocked') doorLocked: boolean = true
  @StorageLink('curtainOpen') curtainOpen: boolean = false
  @StorageLink('cameraOn') cameraOn: boolean = true
  @StorageLink('socketOn') socketOn: boolean = true
  @StorageLink('tvOn') tvOn: boolean = false
  @StorageLink('airPurifierOn') airPurifierOn: boolean = false
  @StorageLink('robotVacuumOn') robotVacuumOn: boolean = false
  @StorageLink('waterHeaterOn') waterHeaterOn: boolean = false
  @StorageLink('doorSensorOn') doorSensorOn: boolean = true
  @StorageLink('bedsideLampOn') bedsideLampOn: boolean = false
  
  @StorageProp('isDarkMode') isDark: boolean = false
  
  // 当前分类
  @State private currentCategory: DeviceCategory = 'all'
  
  // 分类列表
  private readonly categories: CategoryItem[] = [
    { id: 'all', name: '全部', icon: '📱' } as CategoryItem,
    { id: 'light', name: '照明', icon: '💡' } as CategoryItem,
    { id: 'climate', name: '温控', icon: '❄️' } as CategoryItem,
    { id: 'security', name: '安防', icon: '🔒' } as CategoryItem,
    { id: 'appliance', name: '家电', icon: '🔌' } as CategoryItem
  ]
  
  // 动态获取设备列表（响应全局状态）
  private getDevices(): DeviceModel[] {
    return [
      { id: 'light1', name: '客厅灯', icon: '💡', room: '客厅', status: 'online', isOn: this.lightOn, value: '亮度 80%' } as DeviceModel,
      { id: 'light2', name: '卧室灯', icon: '💡', room: '卧室', status: 'online', isOn: this.bedroomLightOn, value: '已关闭' } as DeviceModel,
      { id: 'light3', name: '厨房灯', icon: '💡', room: '厨房', status: 'online', isOn: this.kitchenLightOn, value: '亮度 60%' } as DeviceModel,
      { id: 'air', name: '空调', icon: '❄️', room: '客厅', status: 'online', isOn: this.airOn, value: '26℃' } as DeviceModel,
      { id: 'heater', name: '地暖', icon: '🔥', room: '客厅', status: 'offline', isOn: this.heaterOn, value: '离线' } as DeviceModel,
      { id: 'door', name: '智能门锁', icon: '🚪', room: '入户', status: 'online', isOn: this.doorLocked, value: '已上锁' } as DeviceModel,
      { id: 'camera', name: '摄像头', icon: '📹', room: '客厅', status: 'online', isOn: this.cameraOn, value: '监控中' } as DeviceModel,
      { id: 'curtain', name: '智能窗帘', icon: '🪟', room: '客厅', status: 'online', isOn: this.curtainOpen, value: '已关闭' } as DeviceModel,
      { id: 'socket', name: '智能插座', icon: '🔌', room: '卧室', status: 'online', isOn: this.socketOn, value: '供电中' } as DeviceModel,
      { id: 'tv', name: '智能电视', icon: '📺', room: '客厅', status: 'online', isOn: this.tvOn, value: '待机' } as DeviceModel,
      { id: 'airPurifier', name: '空气净化器', icon: '💨', room: '卧室', status: 'online', isOn: this.airPurifierOn, value: '净化中' } as DeviceModel,
      { id: 'robotVacuum', name: '扫地机器人', icon: '🤖', room: '客厅', status: 'online', isOn: this.robotVacuumOn, value: '清扫中' } as DeviceModel,
      { id: 'waterHeater', name: '热水器', icon: '♨️', room: '卫生间', status: 'online', isOn: this.waterHeaterOn, value: '加热中' } as DeviceModel,
      { id: 'doorSensor', name: '门磁传感器', icon: '📡', room: '入户', status: 'online', isOn: this.doorSensorOn, value: '监控中' } as DeviceModel,
      { id: 'bedsideLamp', name: '床头灯', icon: '💡', room: '卧室', status: 'online', isOn: this.bedsideLampOn, value: '已关闭' } as DeviceModel
    ]
  }
  
  // 获取过滤后的设备列表
  private getFilteredDevices(): DeviceModel[] {
    const devices = this.getDevices()
    
    if (this.currentCategory === 'all') {
      return devices
    }
    
    // 根据分类过滤
    const categoryMap: Record<string, string[]> = {
      'light': ['💡'],
      'climate': ['❄️', '🔥'],
      'security': ['🚪', '📹', '🔒', '📡'],
      'appliance': ['🪟', '🔌', '📺', '🎵', '💨', '🤖', '♨️']
    }
    
    const icons = categoryMap[this.currentCategory] || []
    return devices.filter(device => icons.includes(device.icon))
  }
  
  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar()

      // 智能照明中心入口（人体感应 + IFTTT 联动）
      this.LightingCenterEntry()

      // 分类筛选
      this.CategoryFilter()
      
      // 设备列表
      Scroll() {
        Column({ space: 4 }) {
          ForEach(this.getFilteredDevices(), (device: DeviceModel) => {
            DeviceCard({
              device: device,
              onTap: () => {
                // 门锁设备：跳转到远程开锁专用页（带二次确认 + 日志审计）
                if (device.id === 'door') {
                  router.pushUrl({ url: 'pages/DoorLockPage' })
                } else {
                  // TODO: 跳转到设备详情页
                  console.info(`Navigate to device detail: ${device.id}`)
                }
              },
              onToggle: (isOn: boolean) => {
                // 直接更新全局状态
                if (device.id === 'light1') {
                  DeviceStore.setLightOn(isOn)
                } else if (device.id === 'light2') {
                  DeviceStore.setBedroomLightOn(isOn)
                } else if (device.id === 'light3') {
                  DeviceStore.setKitchenLightOn(isOn)
                } else if (device.id === 'air') {
                  DeviceStore.setAirOn(isOn)
                } else if (device.id === 'heater') {
                  DeviceStore.setHeaterOn(isOn)
                } else if (device.id === 'door') {
                  DeviceStore.setDoorLocked(isOn)
                } else if (device.id === 'camera') {
                  DeviceStore.setCameraOn(isOn)
                } else if (device.id === 'curtain') {
                  DeviceStore.setCurtainOpen(isOn)
                } else if (device.id === 'socket') {
                  DeviceStore.setSocketOn(isOn)
                } else if (device.id === 'tv') {
                  DeviceStore.setTvOn(isOn)
                } else if (device.id === 'airPurifier') {
                  DeviceStore.setAirPurifierOn(isOn)
                } else if (device.id === 'robotVacuum') {
                  DeviceStore.setRobotVacuumOn(isOn)
                } else if (device.id === 'waterHeater') {
                  DeviceStore.setWaterHeaterOn(isOn)
                } else if (device.id === 'doorSensor') {
                  DeviceStore.setDoorSensorOn(isOn)
                } else if (device.id === 'bedsideLamp') {
                  DeviceStore.setBedsideLampOn(isOn)
                }
              }
            })
          })
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
  
  // 智能照明中心入口横幅（跳转到 LightingPage）
  @Builder LightingCenterEntry() {
    Row() {
      Row({ space: 12 }) {
        Text('💡')
          .fontSize(28)
        Column() {
          Text('智能照明中心')
            .fontSize(15)
            .fontWeight(600)
            .fontColor(ThemeColors.textPrimary(this.isDark))
          Text('人体感应 · IFTTT 联动 · 模拟触发')
            .fontSize(11)
            .fontColor(ThemeColors.textSecondary(this.isDark))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('›')
          .fontSize(22)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor(ThemeColors.surface(this.isDark))
      .borderRadius(BorderRadius.MEDIUM)
      .border({
        width: 1,
        color: ThemeColors.divider(this.isDark)
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/LightingPage' }).catch((err: Error) => {
          console.error('LightingPage navigation failed:', err.message)
        })
      })
    }
    .width('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.MD, bottom: Spacing.MD })
  }

  // 标题栏
  @Builder TitleBar() {
    Row() {
      Text('设备管理')
        .fontSize(FontSize.TITLE1)
        .fontWeight(700)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
      Blank()
      
      // 添加设备按钮
      Row({ space: 4 }) {
        Text('+')
          .fontSize(24)
          .fontColor(Colors.BRAND_PRIMARY)
        
        Text('添加')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(BorderRadius.MEDIUM)
      .backgroundColor(Colors.BRAND_PRIMARY + '10')  // 6% 透明度
      .onClick(() => {
        router.pushUrl({ url: 'pages/DeviceAddPage' })
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  // 分类筛选
  @Builder CategoryFilter() {
    Scroll() {
      Row({ space: Spacing.SM }) {
        ForEach(this.categories, (category: CategoryItem) => {
          Column({ space: 4 }) {
            Text(category.icon)
              .fontSize(20)
            
            Text(category.name)
              .fontSize(FontSize.CAPTION1)
              .fontColor(this.currentCategory === category.id ? Colors.BRAND_PRIMARY : ThemeColors.textSecondary(this.isDark))
          }
          .width(60)
          .padding({ top: 8, bottom: 8 })
          .borderRadius(BorderRadius.MEDIUM)
          .backgroundColor(this.currentCategory === category.id ? ThemeColors.selectedBg(this.isDark) : ThemeColors.itemBg(this.isDark))
          .onClick(() => {
            this.currentCategory = category.id as DeviceCategory
          })
        })
      }
      .padding({ left: Spacing.LG, right: Spacing.LG })
    }
    .width('100%')
    .height(70)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
}
