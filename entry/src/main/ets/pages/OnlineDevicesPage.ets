/**
 * 在线设备详情页 - 设备在线状态总览
 * 展示所有设备在线状态、设备分类、快速操作
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
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
  @StorageProp('isDarkMode') isDark: boolean = false
  
  @State private devices: DeviceInfo[] = []
  
  aboutToAppear() {
    this.loadDevices()
  }
  
  build() {
    Column() {
      this.NavigationBar()
      
      Scroll() {
        Column({ space: Spacing.LG }) {
          this.OnlineStatsCard()
          this.CategoryStatsCard()
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
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
  
  @Builder NavigationBar() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .onClick(() => {
          router.back()
        })
      
      Text('在线设备')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .margin({ left: Spacing.MD })
      
      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
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
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.LG })
        
        Blank()
        
        Column({ space: 4 }) {
          Text(this.getOnlineStatus())
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor(Colors.SUCCESS)
          
          Text(`${this.devices.length - this.onlineDevices} 台离线`)
            .fontSize(FontSize.CAPTION1)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: 8,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 2
    })
  }
  
  @Builder CategoryStatsCard() {
    Column({ space: Spacing.MD }) {
      Text('设备分类')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
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
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder CategoryItem(icon: string, name: string, online: number, total: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(24)
      
      Text(name)
        .fontSize(FontSize.CAPTION1)
        .fontColor(ThemeColors.textSecondary(this.isDark))
      
      Text(`${online}/${total}`)
        .fontSize(FontSize.BODY2)
        .fontWeight(600)
        .fontColor(online === total ? Colors.SUCCESS : Colors.WARNING)
    }
    .layoutWeight(1)
    .padding(Spacing.SM)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
  
  @Builder DeviceListCard() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('设备列表')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
        
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
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder DeviceItem(device: DeviceInfo) {
    Row() {
      Text(device.icon)
        .fontSize(24)
      
      Column({ space: 2 }) {
        Text(device.name)
          .fontSize(FontSize.BODY1)
          .fontColor(ThemeColors.textPrimary(this.isDark))
        
        Text(device.room)
          .fontSize(FontSize.CAPTION2)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.SM })
      
      Blank()
      
      Row({ space: 4 }) {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(device.isOnline ? Colors.SUCCESS : ThemeColors.textSecondary(this.isDark))
        
        Text(device.isOnline ? '在线' : '离线')
          .fontSize(FontSize.CAPTION2)
          .fontColor(device.isOnline ? Colors.SUCCESS : ThemeColors.textSecondary(this.isDark))
      }
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
  }
  
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
  
  private getOnlineStatus(): string {
    const total = this.devices.length
    const ratio = this.onlineDevices / total
    if (ratio >= 0.8) return '状态良好'
    if (ratio >= 0.5) return '部分离线'
    return '多数离线'
  }
  
  private getLightCount(): number {
    let count = 0
    if (this.lightOn) count++
    if (this.bedroomLightOn) count++
    if (this.kitchenLightOn) count++
    return count
  }
  
  private getTempControlCount(): number {
    let count = 0
    if (this.airOn) count++
    if (this.heaterOn) count++
    return count
  }
  
  private getSecurityCount(): number {
    let count = 0
    if (this.doorLocked) count++
    if (this.cameraOn) count++
    return count
  }
  
  private getEntertainmentCount(): number {
    let count = 0
    if (this.tvOn) count++
    if (this.socketOn) count++
    return count
  }
}

interface DeviceInfo {
  id: string
  name: string
  icon: string
  room: string
  isOnline: boolean
}
