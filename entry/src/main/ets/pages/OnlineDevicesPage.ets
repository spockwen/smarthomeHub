/**
 * 在线设备详情页 - 设备在线状态总览
 * 展示所有设备在线状态、设备分类、快速操作
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius } from '../common/DesignConstants'
import router from '@ohos.router'

@Entry
@Component
struct OnlineDevicesPage {
  @StorageLink('onlineDevices') onlineDevices: number = 12
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
  
  @State private devices: DeviceInfo[] = []
  
  aboutToAppear() {
    this.loadDevices()
  }
  
  build() {
    Column() {
      // 顶部导航栏
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          // 在线设备统计卡片
          this.OnlineStatsCard()
          
          // 设备分类统计
          this.CategoryStatsCard()
          
          // 设备列表
          this.DeviceListCard()
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
  
  // 导航栏
  @Builder NavigationBar() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        .onClick(() => {
          router.back()
        })
      
      Text('在线设备')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        .margin({ left: Spacing.MD })
      
      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 在线设备统计卡片
  @Builder OnlineStatsCard() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text('🔗')
          .fontSize(40)
        
        Column({ space: 4 }) {
          Text(`${this.onlineDevices}`)
            .fontSize(48)
            .fontWeight(700)
            .fontColor(Colors.SUCCESS)
          
          Text('在线设备')
            .fontSize(FontSize.BODY2)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.LG })
        
        Blank()
        
        // 设备状态指示
        Column({ space: 4 }) {
          Text(this.getOnlineStatus())
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor(Colors.SUCCESS)
          
          Text(`${this.devices.length - this.onlineDevices} 台离线`)
            .fontSize(FontSize.CAPTION1)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
  
  // 设备分类统计
  @Builder CategoryStatsCard() {
    Column({ space: Spacing.MD }) {
      Text('设备分类')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
      Row({ space: Spacing.SM }) {
        this.CategoryItem('💡', '照明', this.getLightCount(), 3)
        this.CategoryItem('❄️', '温控', this.getTempControlCount(), 2)
        this.CategoryItem('🔒', '安防', this.getSecurityCount(), 2)
        this.CategoryItem('📺', '娱乐', this.getEntertainmentCount(), 2)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 分类项
  @Builder CategoryItem(icon: string, name: string, online: number, total: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(24)
      
      Text(name)
        .fontSize(FontSize.CAPTION1)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
      
      Text(`${online}/${total}`)
        .fontSize(FontSize.BODY2)
        .fontWeight(600)
        .fontColor(online === total ? Colors.SUCCESS : Colors.WARNING)
    }
    .layoutWeight(1)
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(Colors.BG_LIGHT)
  }
  
  // 设备列表
  @Builder DeviceListCard() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('设备列表')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Blank()
        
        Text('刷新')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            this.loadDevices()
          })
      }
      .width('100%')
      
      ForEach(this.devices, (device: DeviceInfo) => {
        this.DeviceItem(device)
      })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 设备项
  @Builder DeviceItem(device: DeviceInfo) {
    Row() {
      Text(device.icon)
        .fontSize(24)
      
      Column({ space: 2 }) {
        Text(device.name)
          .fontSize(FontSize.BODY1)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Text(device.room)
          .fontSize(FontSize.CAPTION2)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.SM })
      
      Blank()
      
      // 在线状态指示
      Row({ space: 4 }) {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(device.isOnline ? Colors.SUCCESS : Colors.TEXT_SECONDARY_LIGHT)
        
        Text(device.isOnline ? '在线' : '离线')
          .fontSize(FontSize.CAPTION2)
          .fontColor(device.isOnline ? Colors.SUCCESS : Colors.TEXT_SECONDARY_LIGHT)
      }
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
  }
  
  // 加载设备数据
  private loadDevices() {
    this.devices = [
      { id: 'light', name: '客厅灯', icon: '💡', room: '客厅', isOnline: true },
      { id: 'bedroomLight', name: '卧室灯', icon: '💡', room: '卧室', isOnline: this.bedroomLightOn },
      { id: 'kitchenLight', name: '厨房灯', icon: '💡', room: '厨房', isOnline: true },
      { id: 'air', name: '空调', icon: '❄️', room: '客厅', isOnline: true },
      { id: 'heater', name: '暖气', icon: '🔥', room: '客厅', isOnline: true },
      { id: 'door', name: '智能门锁', icon: '🚪', room: '入户', isOnline: true },
      { id: 'camera', name: '摄像头', icon: '📷', room: '客厅', isOnline: this.cameraOn },
      { id: 'curtain', name: '智能窗帘', icon: '🪟', room: '客厅', isOnline: true },
      { id: 'tv', name: '智能电视', icon: '📺', room: '客厅', isOnline: true },
      { id: 'socket', name: '智能插座', icon: '🔌', room: '客厅', isOnline: this.socketOn }
    ]
  }
  
  // 获取在线状态
  private getOnlineStatus(): string {
    const total = this.devices.length
    const ratio = this.onlineDevices / total
    if (ratio >= 0.8) return '状态良好'
    if (ratio >= 0.5) return '部分离线'
    return '多数离线'
  }
  
  // 获取照明设备在线数
  private getLightCount(): number {
    let count = 0
    if (this.lightOn) count++
    if (this.bedroomLightOn) count++
    if (this.kitchenLightOn) count++
    return count
  }
  
  // 获取温控设备在线数
  private getTempControlCount(): number {
    let count = 0
    if (this.airOn) count++
    if (this.heaterOn) count++
    return count
  }
  
  // 获取安防设备在线数
  private getSecurityCount(): number {
    let count = 0
    if (this.doorLocked) count++
    if (this.cameraOn) count++
    return count
  }
  
  // 获取娱乐设备在线数
  private getEntertainmentCount(): number {
    let count = 0
    if (this.tvOn) count++
    if (this.socketOn) count++
    return count
  }
}

// 设备信息接口
interface DeviceInfo {
  id: string
  name: string
  icon: string
  room: string
  isOnline: boolean
}
