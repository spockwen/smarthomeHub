/**
 * 设备管理页 - 设备列表 + 分类筛选
 * 基于 HarmonyOS Design 规范实现
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius } from '../common/DesignConstants'
import { DeviceCard, DeviceModel } from '../components/DeviceCard'

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
  
  // 设备列表
  @State private devices: DeviceModel[] = [
    { id: 'light1', name: '客厅灯', icon: '💡', room: '客厅', status: 'online', isOn: true, value: '亮度 80%' } as DeviceModel,
    { id: 'light2', name: '卧室灯', icon: '💡', room: '卧室', status: 'online', isOn: false, value: '已关闭' } as DeviceModel,
    { id: 'light3', name: '厨房灯', icon: '💡', room: '厨房', status: 'online', isOn: true, value: '亮度 60%' } as DeviceModel,
    { id: 'air', name: '空调', icon: '❄️', room: '客厅', status: 'online', isOn: false, value: '26℃' } as DeviceModel,
    { id: 'heater', name: '地暖', icon: '🔥', room: '客厅', status: 'offline', isOn: false, value: '离线' } as DeviceModel,
    { id: 'door', name: '智能门锁', icon: '🚪', room: '入户', status: 'online', isOn: true, value: '已上锁' } as DeviceModel,
    { id: 'camera', name: '摄像头', icon: '📹', room: '客厅', status: 'online', isOn: true, value: '监控中' } as DeviceModel,
    { id: 'curtain', name: '智能窗帘', icon: '🪟', room: '客厅', status: 'online', isOn: false, value: '已关闭' } as DeviceModel,
    { id: 'socket', name: '智能插座', icon: '🔌', room: '卧室', status: 'online', isOn: true, value: '供电中' } as DeviceModel,
    { id: 'tv', name: '智能电视', icon: '📺', room: '客厅', status: 'online', isOn: false, value: '待机' } as DeviceModel
  ]
  
  // 获取过滤后的设备列表
  private getFilteredDevices(): DeviceModel[] {
    if (this.currentCategory === 'all') {
      return this.devices
    }
    
    // 根据分类过滤
    const categoryMap: Record<string, string[]> = {
      'light': ['💡'],
      'climate': ['❄️', '🔥'],
      'security': ['🚪', '📹', '🔒'],
      'appliance': ['🪟', '🔌', '📺', '🎵']
    }
    
    const icons = categoryMap[this.currentCategory] || []
    return this.devices.filter(device => icons.includes(device.icon))
  }
  
  // 更新设备状态
  private updateDeviceState(deviceId: string, isOn: boolean) {
    this.devices = this.devices.map(device => {
      if (device.id === deviceId) {
        return {
          id: device.id,
          name: device.name,
          icon: device.icon,
          room: device.room,
          status: device.status,
          isOn: isOn,
          value: device.value
        }
      }
      return device
    })
    
    // 同步到全局状态
    if (deviceId === 'light1') {
      DeviceStore.setLightOn(isOn)
    } else if (deviceId === 'light2') {
      DeviceStore.setBedroomLightOn(isOn)
    } else if (deviceId === 'light3') {
      DeviceStore.setKitchenLightOn(isOn)
    } else if (deviceId === 'air') {
      DeviceStore.setAirOn(isOn)
    } else if (deviceId === 'heater') {
      DeviceStore.setHeaterOn(isOn)
    } else if (deviceId === 'door') {
      DeviceStore.setDoorLocked(isOn)
    } else if (deviceId === 'camera') {
      DeviceStore.setCameraOn(isOn)
    } else if (deviceId === 'curtain') {
      DeviceStore.setCurtainOpen(isOn)
    } else if (deviceId === 'socket') {
      DeviceStore.setSocketOn(isOn)
    } else if (deviceId === 'tv') {
      DeviceStore.setTvOn(isOn)
    }
  }
  
  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar()
      
      // 分类筛选
      this.CategoryFilter()
      
      // 设备列表
      Scroll() {
        Column({ space: 4 }) {
          ForEach(this.getFilteredDevices(), (device: DeviceModel) => {
            DeviceCard({
              device: device,
              onTap: () => {
                // TODO: 跳转到设备详情页
                console.info(`Navigate to device detail: ${device.id}`)
              },
              onToggle: (isOn: boolean) => {
                this.updateDeviceState(device.id, isOn)
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
    .backgroundColor(Colors.BG_LIGHT)
  }
  
  // 标题栏
  @Builder TitleBar() {
    Row() {
      Text('设备管理')
        .fontSize(FontSize.TITLE1)
        .fontWeight(700)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
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
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(Colors.SURFACE_LIGHT)
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
              .fontColor(this.currentCategory === category.id ? Colors.BRAND_PRIMARY : Colors.TEXT_SECONDARY_LIGHT)
          }
          .width(60)
          .padding({ top: 8, bottom: 8 })
          .borderRadius(BorderRadius.MEDIUM)
          .backgroundColor(this.currentCategory === category.id ? Colors.BRAND_PRIMARY + '15' : '#F5F5F5')
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
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
}
