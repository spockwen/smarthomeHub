/**
 * 首页 - 设备概览 + 快捷场景 + 环境卡片
 * 基于 HarmonyOS Design 规范实现
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'
import { SceneCard, SceneModel } from '../components/SceneCard'
import { DeviceCard, DeviceModel } from '../components/DeviceCard'

@Component
export struct HomePage {
  // 全局状态
  @StorageLink('temperature') temperature: number = 26
  @StorageLink('humidity') humidity: number = 72
  @StorageLink('powerUsage') powerUsage: number = 8.5
  @StorageLink('onlineDevices') onlineDevices: number = 12
  @StorageLink('lightOn') lightOn: boolean = true
  @StorageLink('airOn') airOn: boolean = false
  @StorageLink('doorLocked') doorLocked: boolean = true
  @StorageLink('curtainOpen') curtainOpen: boolean = false
  
  // 场景数据
  @State private scenes: SceneModel[] = []
  
  // 设备数据
  @State private devices: DeviceModel[] = []
  
  aboutToAppear() {
    // 初始化设备数据
    const lightDevice: DeviceModel = { id: 'light', name: '客厅灯', icon: '💡', room: '客厅', status: 'online', isOn: true, value: '亮度 80%' }
    const airDevice: DeviceModel = { id: 'air', name: '空调', icon: '❄️', room: '客厅', status: 'online', isOn: false, value: '26℃' }
    const doorDevice: DeviceModel = { id: 'door', name: '智能门锁', icon: '🚪', room: '入户', status: 'online', isOn: true, value: '已上锁' }
    const curtainDevice: DeviceModel = { id: 'curtain', name: '智能窗帘', icon: '🪟', room: '客厅', status: 'online', isOn: false, value: '已关闭' }
    this.devices = [lightDevice, airDevice, doorDevice, curtainDevice]
    
    // 初始化场景数据
    const homeScene: SceneModel = { id: 'home', name: '回家', icon: '🏠', color: '#007DFF', isActive: false, deviceCount: 5 }
    const leaveScene: SceneModel = { id: 'leave', name: '离家', icon: '🚶', color: '#00A5FF', isActive: false, deviceCount: 8 }
    const sleepScene: SceneModel = { id: 'sleep', name: '睡眠', icon: '🌙', color: '#6B7280', isActive: false, deviceCount: 4 }
    const movieScene: SceneModel = { id: 'movie', name: '观影', icon: '🎬', color: '#8B5CF6', isActive: false, deviceCount: 3 }
    this.scenes = [homeScene, leaveScene, sleepScene, movieScene]
  }
  
  // 触发场景
  private triggerScene(sceneId: string) {
    this.scenes = this.scenes.map(scene => {
      const updatedScene: SceneModel = {
        id: scene.id,
        name: scene.name,
        icon: scene.icon,
        color: scene.color,
        isActive: scene.id === sceneId ? !scene.isActive : false,
        deviceCount: scene.deviceCount
      }
      return updatedScene
    })
    
    // 根据场景执行设备操作
    if (sceneId === 'home') {
      DeviceStore.setLightOn(true)
      DeviceStore.setAirOn(true)
      DeviceStore.setCurtainOpen(false)
    } else if (sceneId === 'leave') {
      DeviceStore.setLightOn(false)
      DeviceStore.setAirOn(false)
      DeviceStore.setDoorLocked(true)
    } else if (sceneId === 'sleep') {
      DeviceStore.setLightOn(false)
      DeviceStore.setAirOn(true)
      DeviceStore.setCurtainOpen(false)
    } else if (sceneId === 'movie') {
      DeviceStore.setLightOn(true)
      DeviceStore.setCurtainOpen(false)
    }
  }
  
  build() {
    Scroll() {
      Column({ space: Spacing.XL }) {
        // 顶部标题栏
        this.TitleSection()
        
        // 环境信息卡片
        this.EnvironmentSection()
        
        // 快捷场景
        this.SceneSection()
        
        // 设备概览
        this.DeviceSection()
      }
      .width('100%')
      .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XXL })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BG_LIGHT)
    .scrollBar(BarState.Off)
  }
  
  // 标题栏
  @Builder TitleSection() {
    Row() {
      Column({ space: 4 }) {
        Text('鸿蒙智家')
          .fontSize(FontSize.TITLE1)
          .fontWeight(700)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Text('AI Hub')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
    }
    .width('100%')
    .margin({ top: Spacing.LG })
  }
  
  // 环境信息卡片
  @Builder EnvironmentSection() {
    Row({ space: Spacing.SM }) {
      // 温度
      this.EnvCard('🌡️', `${this.temperature}℃`, '室内温度', Colors.BRAND_PRIMARY)
      
      // 湿度
      this.EnvCard('💧', `${this.humidity}%`, '室内湿度', Colors.BRAND_SECONDARY)
      
      // 能耗
      this.EnvCard('⚡', `${this.powerUsage}kWh`, '今日能耗', Colors.WARNING)
      
      // 在线设备
      this.EnvCard('🔗', `${this.onlineDevices}`, '在线设备', Colors.SUCCESS)
    }
    .width('100%')
  }
  
  // 环境卡片子组件
  @Builder EnvCard(icon: string, value: string, label: string, color: string) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(28)
      
      Text(value)
        .fontSize(FontSize.TITLE3)
        .fontWeight(700)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
      Text(label)
        .fontSize(FontSize.CAPTION1)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
    }
    .width('25%')
    .padding(Spacing.MD)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
  
  // 快捷场景区域
  @Builder SceneSection() {
    Column({ space: Spacing.MD }) {
      // 标题
      Row() {
        Text('快捷场景')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Blank()
        
        Text('查看全部 >')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            AppStorage.setOrCreate('navToScene', true)
            setTimeout(() => AppStorage.setOrCreate('navToScene', false), 100)
          })
      }
      .width('100%')
      
      // 场景卡片网格
      Grid() {
        ForEach(this.scenes, (scene: SceneModel) => {
          GridItem() {
            SceneCard({
              scene: scene,
              onTap: () => {
                this.triggerScene(scene.id)
              }
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(Spacing.MD)
      .columnsGap(Spacing.SM)
      .width('100%')
      .height(140)
    }
    .width('100%')
  }
  
  // 设备概览区域
  @Builder DeviceSection() {
    Column({ space: Spacing.MD }) {
      // 标题
      Row() {
        Text('我的设备')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Blank()
        
        Text('管理 >')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            AppStorage.setOrCreate('navToDevice', true)
            setTimeout(() => AppStorage.setOrCreate('navToDevice', false), 100)
          })
      }
      .width('100%')
      
      // 设备列表
      Column({ space: 0 }) {
        ForEach(this.devices, (device: DeviceModel) => {
          DeviceCard({
            device: device,
            compact: true,
            onToggle: (isOn: boolean) => {
              // 更新设备状态
              if (device.id === 'light') {
                DeviceStore.setLightOn(isOn)
              } else if (device.id === 'air') {
                DeviceStore.setAirOn(isOn)
              } else if (device.id === 'door') {
                DeviceStore.setDoorLocked(isOn)
              } else if (device.id === 'curtain') {
                DeviceStore.setCurtainOpen(isOn)
              }
            }
          })
        })
      }
      .width('100%')
    }
    .width('100%')
  }
}
