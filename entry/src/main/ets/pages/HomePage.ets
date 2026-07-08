/**
 * 首页 - 设备概览 + 快捷场景 + 环境卡片
 * 基于 HarmonyOS Design 规范实现
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig, ThemeColors } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'
import { SceneCard, SceneModel } from '../components/SceneCard'
import { DeviceCard, DeviceModel } from '../components/DeviceCard'
import router from '@ohos.router'
import curves from '@ohos.curves'

interface AllDeviceItem {
  id: string
  name: string
  icon: string
}

interface HomeDeviceItem {
  id: string
  name: string
  icon: string
  room: string
  status: DeviceStatus
  value: string
}

type DeviceStatus = 'online' | 'offline' | 'warning'

@Component
export struct HomePage {
  @StorageLink('temperature') temperature: number = 26
  @StorageLink('humidity') humidity: number = 72
  @StorageLink('powerUsage') powerUsage: number = 8.5
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
  @StorageLink('airPurifierOn') airPurifierOn: boolean = false
  @StorageLink('robotVacuumOn') robotVacuumOn: boolean = false
  @StorageLink('waterHeaterOn') waterHeaterOn: boolean = false
  @StorageLink('doorSensorOn') doorSensorOn: boolean = true
  @StorageLink('bedsideLampOn') bedsideLampOn: boolean = false
  @StorageLink('activeScene') @Watch('onActiveSceneChange') activeScene: string = ''
  @StorageLink('homeDeviceIds') @Watch('onHomeIdsChange') homeDeviceIdsStr: string = 'light1,air,door,curtain'
  @StorageProp('isDarkMode') isDark: boolean = false
  
  @State private scenes: SceneModel[] = []
  @State private showAddSheet: boolean = false
  @State private isEditing: boolean = false
  @State private homeDeviceList: HomeDeviceItem[] = []
  @State private dragItem: string = ''
  @State private scaleItem: string = ''
  @State private offsetY: number = 0
  private dragRefOffset: number = 0
  private readonly itemHeight: number = 88
  
  private onHomeIdsChange(): void {
    this.homeDeviceList = this.buildHomeDeviceList()
  }
  
  // 监听全局场景状态变化
  private onActiveSceneChange(): void {
    this.scenes = this.scenes.map(scene => {
      const updatedScene: SceneModel = {
        id: scene.id,
        name: scene.name,
        icon: scene.icon,
        color: scene.color,
        isActive: scene.id === this.activeScene,
        deviceCount: scene.deviceCount
      }
      return updatedScene
    })
  }
  
  aboutToAppear() {
    const homeScene: SceneModel = { id: 'home', name: '回家', icon: '🏠', color: '#007DFF', isActive: this.activeScene === 'home', deviceCount: 5 }
    const leaveScene: SceneModel = { id: 'leave', name: '离家', icon: '🚶', color: '#00A5FF', isActive: this.activeScene === 'leave', deviceCount: 8 }
    const sleepScene: SceneModel = { id: 'sleep', name: '睡眠', icon: '🌙', color: '#6B7280', isActive: this.activeScene === 'sleep', deviceCount: 4 }
    const movieScene: SceneModel = { id: 'movie', name: '观影', icon: '🎬', color: '#8B5CF6', isActive: this.activeScene === 'movie', deviceCount: 3 }
    this.scenes = [homeScene, leaveScene, sleepScene, movieScene]
    this.homeDeviceList = this.buildHomeDeviceList()
  }
  
  private buildHomeDeviceList(): HomeDeviceItem[] {
    const ids = this.homeDeviceIdsStr.split(',').filter((id: string) => id.length > 0)
    const allMap: Record<string, HomeDeviceItem> = {
      'light1': { id: 'light1', name: '客厅灯', icon: '💡', room: '客厅', status: 'online', value: '亮度 80%' },
      'light2': { id: 'light2', name: '卧室灯', icon: '💡', room: '卧室', status: 'online', value: '已关闭' },
      'light3': { id: 'light3', name: '厨房灯', icon: '💡', room: '厨房', status: 'online', value: '亮度 60%' },
      'air': { id: 'air', name: '空调', icon: '❄️', room: '客厅', status: 'online', value: '26℃' },
      'heater': { id: 'heater', name: '地暖', icon: '🔥', room: '客厅', status: 'offline', value: '离线' },
      'door': { id: 'door', name: '智能门锁', icon: '🚪', room: '入户', status: 'online', value: '已上锁' },
      'camera': { id: 'camera', name: '摄像头', icon: '📹', room: '客厅', status: 'online', value: '监控中' },
      'curtain': { id: 'curtain', name: '智能窗帘', icon: '🪟', room: '客厅', status: 'online', value: '已关闭' },
      'socket': { id: 'socket', name: '智能插座', icon: '🔌', room: '卧室', status: 'online', value: '供电中' },
      'tv': { id: 'tv', name: '智能电视', icon: '📺', room: '客厅', status: 'online', value: '待机' },
      'airPurifier': { id: 'airPurifier', name: '空气净化器', icon: '💨', room: '卧室', status: 'online', value: '净化中' },
      'robotVacuum': { id: 'robotVacuum', name: '扫地机器人', icon: '🤖', room: '客厅', status: 'online', value: '清扫中' },
      'waterHeater': { id: 'waterHeater', name: '热水器', icon: '♨️', room: '卫生间', status: 'online', value: '加热中' },
      'doorSensor': { id: 'doorSensor', name: '门磁传感器', icon: '📡', room: '入户', status: 'online', value: '监控中' },
      'bedsideLamp': { id: 'bedsideLamp', name: '床头灯', icon: '💡', room: '卧室', status: 'online', value: '已关闭' }
    }
    const list: HomeDeviceItem[] = []
    for (const id of ids) {
      if (allMap[id]) {
        list.push(allMap[id])
      }
    }
    return list
  }
  
  private getDeviceIsOn(id: string): boolean {
    if (id === 'light1') return this.lightOn
    if (id === 'light2') return this.bedroomLightOn
    if (id === 'light3') return this.kitchenLightOn
    if (id === 'air') return this.airOn
    if (id === 'heater') return this.heaterOn
    if (id === 'door') return this.doorLocked
    if (id === 'camera') return this.cameraOn
    if (id === 'curtain') return this.curtainOpen
    if (id === 'socket') return this.socketOn
    if (id === 'tv') return this.tvOn
    if (id === 'airPurifier') return this.airPurifierOn
    if (id === 'robotVacuum') return this.robotVacuumOn
    if (id === 'waterHeater') return this.waterHeaterOn
    if (id === 'doorSensor') return this.doorSensorOn
    if (id === 'bedsideLamp') return this.bedsideLampOn
    return false
  }
  
  private getHomeDeviceIds(): string[] {
    return this.homeDeviceIdsStr.split(',').filter((id: string) => id.length > 0)
  }
  
  private allDevices: AllDeviceItem[] = [
    { id: 'light1', name: '客厅灯', icon: '💡' },
    { id: 'light2', name: '卧室灯', icon: '💡' },
    { id: 'light3', name: '厨房灯', icon: '💡' },
    { id: 'air', name: '空调', icon: '❄️' },
    { id: 'heater', name: '地暖', icon: '🔥' },
    { id: 'door', name: '智能门锁', icon: '🚪' },
    { id: 'camera', name: '摄像头', icon: '📹' },
    { id: 'curtain', name: '智能窗帘', icon: '🪟' },
    { id: 'socket', name: '智能插座', icon: '🔌' },
    { id: 'tv', name: '智能电视', icon: '📺' },
    { id: 'airPurifier', name: '空气净化器', icon: '💨' },
    { id: 'robotVacuum', name: '扫地机器人', icon: '🤖' },
    { id: 'waterHeater', name: '热水器', icon: '♨️' },
    { id: 'doorSensor', name: '门磁传感器', icon: '📡' },
    { id: 'bedsideLamp', name: '床头灯', icon: '💡' }
  ]
  
  private scaleSelect(item: HomeDeviceItem): number {
    if (this.scaleItem === item.id) {
      return 1.05
    }
    return 1
  }
  
  private itemMove(from: number, to: number): void {
    const moved = this.homeDeviceList.splice(from, 1)[0]
    this.homeDeviceList.splice(to, 0, moved)
    const ids = this.homeDeviceList.map((item: HomeDeviceItem) => item.id)
    DeviceStore.setHomeDeviceIds(ids)
  }
  
  private animateReset(): void {
    this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 400, 38) }, () => {
      this.dragItem = ''
      this.offsetY = 0
    })
    this.getUIContext().animateTo({ curve: curves.interpolatingSpring(14, 1, 170, 17), delay: 150 }, () => {
      this.scaleItem = ''
    })
  }
  
  private showRemoveDialog(deviceId: string, deviceName: string): void {
    AlertDialog.show({
      title: '移除设备',
      message: `是否将"${deviceName}"从首页移除？`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '移除',
        fontColor: Colors.ERROR,
        action: () => {
          DeviceStore.removeHomeDevice(deviceId)
        }
      }
    })
  }
  
  private handleToggle(deviceId: string, isOn: boolean): void {
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
    } else if (deviceId === 'airPurifier') {
      DeviceStore.setAirPurifierOn(isOn)
    } else if (deviceId === 'robotVacuum') {
      DeviceStore.setRobotVacuumOn(isOn)
    } else if (deviceId === 'waterHeater') {
      DeviceStore.setWaterHeaterOn(isOn)
    } else if (deviceId === 'doorSensor') {
      DeviceStore.setDoorSensorOn(isOn)
    } else if (deviceId === 'bedsideLamp') {
      DeviceStore.setBedsideLampOn(isOn)
    }
  }
  private triggerScene(sceneId: string) {
    const wasActive = this.activeScene === sceneId
    DeviceStore.triggerScene(sceneId)
    
    this.scenes = this.scenes.map(scene => {
      const updatedScene: SceneModel = {
        id: scene.id,
        name: scene.name,
        icon: scene.icon,
        color: scene.color,
        isActive: scene.id === sceneId && !wasActive,
        deviceCount: scene.deviceCount
      }
      return updatedScene
    })
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
    .backgroundColor(ThemeColors.bg(this.isDark))
    .scrollBar(BarState.Off)
  }
  
  // 标题栏
  @Builder TitleSection() {
    Row() {
      Column({ space: 4 }) {
        Text('鸿蒙智家')
          .fontSize(FontSize.TITLE1)
          .fontWeight(700)
          .fontColor(ThemeColors.textPrimary(this.isDark))
        
        Text('AI Hub')
          .fontSize(FontSize.BODY2)
          .fontColor(ThemeColors.textSecondary(this.isDark))
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
    }
    .width('100%')
    .margin({ top: Spacing.LG })
  }
  
  // 环境信息卡片
  @Builder EnvironmentSection() {
    Flex({ 
      direction: FlexDirection.Row, 
      wrap: FlexWrap.NoWrap, 
      alignItems: ItemAlign.Stretch,
      justifyContent: FlexAlign.SpaceBetween 
    }) {
      // 温度
      this.EnvCard('🌡️', `${this.temperature}℃`, '室内温度', Colors.BRAND_PRIMARY, () => {
        router.pushUrl({ url: 'pages/TemperaturePage' })
      })
      
      // 湿度
      this.EnvCard('💧', `${this.humidity}%`, '室内湿度', Colors.BRAND_SECONDARY, () => {
        router.pushUrl({ url: 'pages/HumidityPage' })
      })
      
      // 能耗
      this.EnvCard('⚡', `${this.powerUsage}kWh`, '今日能耗', Colors.WARNING, () => {
        router.pushUrl({ url: 'pages/PowerUsagePage' })
      })
      
      // 在线设备
      this.EnvCard('🔗', `${this.onlineDevices}`, '在线设备', Colors.SUCCESS, () => {
        router.pushUrl({ url: 'pages/OnlineDevicesPage' })
      })
    }
    .width('100%')
  }
  
  // 环境卡片子组件
  @Builder EnvCard(icon: string, value: string, label: string, color: string, onClick?: () => void) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(24)
      
      Text(value)
        .fontSize(FontSize.TITLE3)
        .fontWeight(700)
        .fontColor(ThemeColors.textPrimary(this.isDark))
      
      Text(label)
        .fontSize(FontSize.CAPTION1)
        .fontColor(ThemeColors.textSecondary(this.isDark))
    }
    .layoutWeight(1)
    .padding(Spacing.MD)
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: 4,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      if (onClick) {
        onClick()
      }
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
          .fontColor(ThemeColors.textPrimary(this.isDark))
        
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
      Row() {
        Text('我的设备')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
        
        if (this.isEditing) {
          Text('编辑中')
            .fontSize(FontSize.CAPTION1)
            .fontColor(Colors.WARNING)
            .margin({ left: Spacing.SM })
        }
        
        Blank()
        
        Row({ space: 4 }) {
          Text('+')
            .fontSize(20)
            .fontColor(Colors.BRAND_PRIMARY)
          
          Text('添加')
            .fontSize(FontSize.CAPTION1)
            .fontColor(Colors.BRAND_PRIMARY)
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(BorderRadius.MEDIUM)
        .backgroundColor(ThemeColors.selectedBg(this.isDark))
        .onClick(() => {
          this.showAddSheet = true
        })
        
        Text('管理 >')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
          .margin({ left: Spacing.MD })
          .onClick(() => {
            AppStorage.setOrCreate('navToDevice', true)
            setTimeout(() => AppStorage.setOrCreate('navToDevice', false), 100)
          })
      }
      .width('100%')
      
      if (this.isEditing) {
        Row() {
          Text('长按拖拽排序，点击 ✕ 移除')
            .fontSize(FontSize.CAPTION1)
            .fontColor(ThemeColors.textSecondary(this.isDark))
            .layoutWeight(1)
          
          Text('完成')
            .fontSize(FontSize.BODY2)
            .fontColor(Colors.BRAND_PRIMARY)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .borderRadius(BorderRadius.MEDIUM)
            .backgroundColor(ThemeColors.selectedBg(this.isDark))
            .onClick(() => {
              this.isEditing = false
            })
        }
        .width('100%')
      }
      
      List({ space: Spacing.SM }) {
        ForEach(this.homeDeviceList, (item: HomeDeviceItem, index: number) => {
          ListItem() {
            Stack({ alignContent: Alignment.TopEnd }) {
              DeviceCard({
                device: {
                  id: item.id,
                  name: item.name,
                  icon: item.icon,
                  room: item.room,
                  status: item.status,
                  isOn: this.getDeviceIsOn(item.id),
                  value: item.value
                } as DeviceModel,
                compact: true,
                onToggle: (isOn: boolean) => {
                  if (this.isEditing) {
                    return
                  }
                  this.handleToggle(item.id, isOn)
                }
              })
              
              if (this.isEditing) {
                Text('✕')
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .width(24)
                  .height(24)
                  .borderRadius(12)
                  .backgroundColor(Colors.ERROR)
                  .textAlign(TextAlign.Center)
                  .margin({ top: 4, right: 4 })
                  .onClick(() => {
                    this.showRemoveDialog(item.id, item.name)
                  })
              }
            }
            .width('100%')
            .scale({ x: this.scaleSelect(item), y: this.scaleSelect(item) })
            .zIndex(this.dragItem === item.id ? 1 : 0)
            .translate(this.dragItem === item.id ? { y: this.offsetY } : { y: 0 })
            .gesture(
              GestureGroup(GestureMode.Sequence,
                LongPressGesture({ repeat: false, duration: 300 })
                  .onAction(() => {
                    this.isEditing = true
                    this.getUIContext().animateTo({ curve: Curve.Friction, duration: 300 }, () => {
                      this.scaleItem = item.id
                    })
                  }),
                PanGesture({ fingers: 1, direction: PanDirection.Vertical, distance: 5 })
                  .onActionStart(() => {
                    if (!this.isEditing) {
                      return
                    }
                    this.dragItem = item.id
                    this.dragRefOffset = 0
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    if (this.dragItem !== item.id) {
                      return
                    }
                    this.offsetY = event.offsetY - this.dragRefOffset
                    const idx = this.homeDeviceList.findIndex((d: HomeDeviceItem) => d.id === item.id)
                    if (this.offsetY > this.itemHeight / 2 && idx < this.homeDeviceList.length - 1) {
                      this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 400, 38) }, () => {
                        this.offsetY -= this.itemHeight
                        this.dragRefOffset += this.itemHeight
                        this.itemMove(idx, idx + 1)
                      })
                    } else if (this.offsetY < -this.itemHeight / 2 && idx > 0) {
                      this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 400, 38) }, () => {
                        this.offsetY += this.itemHeight
                        this.dragRefOffset -= this.itemHeight
                        this.itemMove(idx, idx - 1)
                      })
                    }
                  })
                  .onActionEnd(() => {
                    if (this.dragItem === item.id) {
                      this.animateReset()
                    }
                  })
              ).onCancel(() => {
                this.animateReset()
              })
            )
          }
        }, (item: HomeDeviceItem) => item.id)
      }
      .width('100%')
    }
    .width('100%')
    .bindSheet($$this.showAddSheet, this.AddDeviceSheetBuilder(), {
      height: '60%',
      dragBar: true,
      backgroundColor: ThemeColors.surface(this.isDark),
      onDisappear: () => {
        this.showAddSheet = false
      }
    })
  }
  
  @Builder AddDeviceSheetBuilder() {
    Column({ space: Spacing.MD }) {
      Text('添加设备到首页')
        .fontSize(FontSize.TITLE3)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .width('100%')
        .padding({ left: Spacing.LG, top: Spacing.MD })
      
      Scroll() {
        Column({ space: Spacing.SM }) {
          ForEach(this.allDevices, (item: AllDeviceItem) => {
            Row() {
              Text(item.icon)
                .fontSize(24)
              
              Text(item.name)
                .fontSize(FontSize.BODY1)
                .fontColor(ThemeColors.textPrimary(this.isDark))
                .margin({ left: Spacing.MD })
                .layoutWeight(1)
              
              if (this.getHomeDeviceIds().includes(item.id)) {
                Text('已添加')
                  .fontSize(FontSize.CAPTION1)
                  .fontColor(ThemeColors.textTertiary(this.isDark))
              } else {
                Text('+ 添加')
                  .fontSize(FontSize.CAPTION1)
                  .fontColor(Colors.BRAND_PRIMARY)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(BorderRadius.SMALL)
                  .backgroundColor(ThemeColors.selectedBg(this.isDark))
                  .onClick(() => {
                    DeviceStore.addHomeDevice(item.id)
                  })
              }
            }
            .width('100%')
            .height(56)
            .padding({ left: Spacing.LG, right: Spacing.LG })
            .borderRadius(BorderRadius.MEDIUM)
            .backgroundColor(ThemeColors.itemBg(this.isDark))
          })
        }
        .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
