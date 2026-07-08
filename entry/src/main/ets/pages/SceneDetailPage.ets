/**
 * 场景详情页
 * 统一结构：顶部状态栏 + 返回箭头 + 场景标题 + 描述 + 渐变背景
 * 中间分「启动条件」和「执行结果」两个模块，每个模块下是白色圆角卡片列表
 * 底部无导航栏，仅保留返回逻辑
 */
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import router from '@ohos.router'
import { SceneStore, SceneModel } from '../SceneStore'
import { DeviceStore } from '../DeviceStore'

export interface SceneActionItem {
  id: string
  icon: string
  title: string
  description: string
  deviceId: string
  action: string
}

export interface SceneDetailData {
  id: string
  title: string
  description: string
  gradientColors: string[]
  triggerConditions: SceneActionItem[]
  executionResults: SceneActionItem[]
  sceneId: string
}

@Entry
@Component
export struct SceneDetailPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @StorageLink('activeScene') activeScene: string = ''
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
  @State private sceneId: string = ''
  @State private sceneData: SceneDetailData | null = null
  @State private isUserScene: boolean = false
  @State private userSceneData: SceneModel | null = null

  private readonly sceneDetails: Record<string, SceneDetailData> = {
    'leave_home': {
      id: 'leave_home',
      title: '安心离家',
      description: '离开家后，自动关闭空调、灯、开关，开启空气净化器等',
      gradientColors: ['#F5E6D3', '#D4B483'],
      sceneId: 'leave_home',
      triggerConditions: [
        { id: 'location', icon: '📍', title: '离开某地', description: '离开指定地理位置时触发', deviceId: '', action: '' }
      ],
      executionResults: [
        { id: 'switch', icon: '🔌', title: '开关', description: '关闭智能插座', deviceId: 'socket', action: 'off' },
        { id: 'light', icon: '💡', title: '客厅灯', description: '关闭客厅灯', deviceId: 'light1', action: 'off' },
        { id: 'light2', icon: '💡', title: '卧室灯', description: '关闭卧室灯', deviceId: 'light2', action: 'off' },
        { id: 'light3', icon: '💡', title: '厨房灯', description: '关闭厨房灯', deviceId: 'light3', action: 'off' },
        { id: 'ac', icon: '❄️', title: '空调', description: '关闭空调', deviceId: 'air', action: 'off' },
        { id: 'air_purifier', icon: '💨', title: '空气净化器', description: '开启空气净化器', deviceId: 'airPurifier', action: 'on' },
        { id: 'bedside_lamp', icon: '💡', title: '床头灯', description: '关闭床头灯', deviceId: 'bedsideLamp', action: 'off' },
        { id: 'tv', icon: '📺', title: '电视', description: '关闭电视', deviceId: 'tv', action: 'off' },
        { id: 'door', icon: '🚪', title: '门锁', description: '锁门', deviceId: 'door', action: 'lock' },
        { id: 'camera', icon: '📹', title: '摄像头', description: '开启监控', deviceId: 'camera', action: 'on' }
      ]
    },
    'alert': {
      id: 'alert',
      title: '异常警报',
      description: '当传感器设备检测到异常时会向您推送通知',
      gradientColors: ['#FFD8CC', '#FF9A7A'],
      sceneId: 'alert',
      triggerConditions: [
        { id: 'door_sensor', icon: '📡', title: '门磁传感器', description: '感应门窗开关状态', deviceId: 'doorSensor', action: 'monitor' }
      ],
      executionResults: [
        { id: 'notification', icon: '🔔', title: '推送通知', description: '将给您发送异常告警通知', deviceId: '', action: '' },
        { id: 'camera', icon: '📹', title: '摄像头', description: '开启摄像头录像', deviceId: 'camera', action: 'on' }
      ]
    },
    'morning': {
      id: 'morning',
      title: '早起习惯',
      description: '早晨自动开启灯、空气净化器，关闭空调等，减少起床阻力',
      gradientColors: ['#FFF9E6', '#FFE699'],
      sceneId: 'morning',
      triggerConditions: [
        { id: 'timer', icon: '⏰', title: '定时', description: '按设定时间自动触发', deviceId: '', action: '' }
      ],
      executionResults: [
        { id: 'light', icon: '💡', title: '客厅灯', description: '打开客厅灯', deviceId: 'light1', action: 'on' },
        { id: 'light2', icon: '💡', title: '卧室灯', description: '打开卧室灯', deviceId: 'light2', action: 'on' },
        { id: 'ac', icon: '❄️', title: '空调', description: '关闭空调', deviceId: 'air', action: 'off' },
        { id: 'air_purifier', icon: '💨', title: '空气净化器', description: '开启空气净化器', deviceId: 'airPurifier', action: 'on' },
        { id: 'curtain', icon: '🪟', title: '窗帘', description: '打开窗帘', deviceId: 'curtain', action: 'on' }
      ]
    },
    'sleep': {
      id: 'sleep',
      title: '就寝提醒',
      description: '为你提供适合睡眠的环境，自动开启空调、空气净化器，关闭灯、插座、开关等',
      gradientColors: ['#E8D9C5', '#B89B7D'],
      sceneId: 'sleep_scene',
      triggerConditions: [
        { id: 'timer', icon: '⏰', title: '定时', description: '按设定时间自动触发', deviceId: '', action: '' }
      ],
      executionResults: [
        { id: 'light', icon: '💡', title: '客厅灯', description: '关闭客厅灯', deviceId: 'light1', action: 'off' },
        { id: 'light2', icon: '💡', title: '卧室灯', description: '关闭卧室灯', deviceId: 'light2', action: 'off' },
        { id: 'bedside_lamp', icon: '💡', title: '床头灯', description: '关闭床头灯', deviceId: 'bedsideLamp', action: 'off' },
        { id: 'socket', icon: '🔌', title: '插座', description: '关闭智能插座', deviceId: 'socket', action: 'off' },
        { id: 'ac', icon: '❄️', title: '空调', description: '开启空调（睡眠温度）', deviceId: 'air', action: 'on' },
        { id: 'air_purifier', icon: '💨', title: '空气净化器', description: '开启空气净化器', deviceId: 'airPurifier', action: 'on' },
        { id: 'tv', icon: '📺', title: '电视', description: '关闭电视', deviceId: 'tv', action: 'off' }
      ]
    },
    'back_home': {
      id: 'back_home',
      title: '温馨回家',
      description: '回到家后，一键开启空调、灯、热水器，关闭扫地机器人、空气净化器等',
      gradientColors: ['#F0F0F0', '#D9D9D9'],
      sceneId: 'back_home',
      triggerConditions: [
        { id: 'location', icon: '📍', title: '到达某地', description: '到达指定地理位置时触发', deviceId: '', action: '' }
      ],
      executionResults: [
        { id: 'light', icon: '💡', title: '客厅灯', description: '打开客厅灯', deviceId: 'light1', action: 'on' },
        { id: 'light2', icon: '💡', title: '卧室灯', description: '打开卧室灯', deviceId: 'light2', action: 'on' },
        { id: 'ac', icon: '❄️', title: '空调', description: '开启空调', deviceId: 'air', action: 'on' },
        { id: 'air_purifier', icon: '💨', title: '空气净化器', description: '关闭空气净化器', deviceId: 'airPurifier', action: 'off' },
        { id: 'robot_vacuum', icon: '🤖', title: '扫地机器人', description: '关闭扫地机器人', deviceId: 'robotVacuum', action: 'off' },
        { id: 'water_heater', icon: '♨️', title: '热水器', description: '开启热水器', deviceId: 'waterHeater', action: 'on' }
      ]
    }
  }

  private convertToSceneDetailData(scene: SceneModel): SceneDetailData {
    const triggerConditionItem = {
      id: scene.triggerCondition,
      icon: this.getTriggerIcon(scene.triggerCondition),
      title: SceneStore.getTriggerConditionName(scene.triggerCondition),
      description: this.getTriggerDescription(scene.triggerCondition),
      deviceId: '',
      action: ''
    } as SceneActionItem

    const executionResults = scene.actions.map(actionId => ({
      id: actionId,
      icon: SceneStore.getActionIcon(actionId),
      title: SceneStore.getActionName(actionId),
      description: this.getActionDescription(actionId),
      deviceId: this.getDeviceIdForAction(actionId),
      action: this.getDeviceAction(actionId)
    } as SceneActionItem))

    return {
      id: scene.id,
      title: scene.name,
      description: scene.description || '暂无描述',
      gradientColors: [scene.color, this.adjustColorBrightness(scene.color, 0.8)],
      triggerConditions: [triggerConditionItem],
      executionResults: executionResults,
      sceneId: scene.id
    }
  }

  private getDeviceIdForAction(actionId: string): string {
    const map: Record<string, string> = {
      'turn_on_light': 'light1',
      'turn_off_light': 'light1',
      'turn_on_ac': 'air',
      'turn_off_ac': 'air',
      'lock_door': 'door',
      'unlock_door': 'door',
      'close_curtain': 'curtain',
      'open_curtain': 'curtain',
      'turn_on_socket': 'socket',
      'turn_off_socket': 'socket'
    }
    return map[actionId] || ''
  }

  private getDeviceAction(actionId: string): string {
    const map: Record<string, string> = {
      'turn_on_light': 'on',
      'turn_off_light': 'off',
      'turn_on_ac': 'on',
      'turn_off_ac': 'off',
      'lock_door': 'lock',
      'unlock_door': 'unlock',
      'close_curtain': 'off',
      'open_curtain': 'on',
      'turn_on_socket': 'on',
      'turn_off_socket': 'off'
    }
    return map[actionId] || ''
  }

  private getTriggerIcon(triggerId: string): string {
    const iconMap: Record<string, string> = {
      'leave_location': '📍',
      'arrive_location': '📍',
      'time_schedule': '⏰',
      'device_status': '📱',
      'weather': '☁️',
      'manual': '👆'
    }
    return iconMap[triggerId] || '⚙️'
  }

  private getTriggerDescription(triggerId: string): string {
    const descMap: Record<string, string> = {
      'leave_location': '离开指定地理位置时触发',
      'arrive_location': '到达指定地理位置时触发',
      'time_schedule': '按时间计划触发',
      'device_status': '设备状态变化时触发',
      'weather': '特定天气条件时触发',
      'manual': '手动点击触发'
    }
    return descMap[triggerId] || '未知触发条件'
  }

  private getActionDescription(actionId: string): string {
    const descMap: Record<string, string> = {
      'turn_on_light': '打开指定灯光',
      'turn_off_light': '关闭指定灯光',
      'turn_on_ac': '打开空调并设置温度',
      'turn_off_ac': '关闭空调',
      'lock_door': '锁定智能门锁',
      'unlock_door': '解锁智能门锁',
      'close_curtain': '关闭智能窗帘',
      'open_curtain': '打开智能窗帘',
      'turn_on_socket': '打开智能插座电源',
      'turn_off_socket': '关闭智能插座电源'
    }
    return descMap[actionId] || '执行设备操作'
  }

  private adjustColorBrightness(color: string, factor: number): string {
    if (color.startsWith('#') && color.length === 7) {
      const r = parseInt(color.slice(1, 3), 16)
      const g = parseInt(color.slice(3, 5), 16)
      const b = parseInt(color.slice(5, 7), 16)
      
      const newR = Math.min(255, Math.floor(r * factor))
      const newG = Math.min(255, Math.floor(g * factor))
      const newB = Math.min(255, Math.floor(b * factor))
      
      return `#${newR.toString(16).padStart(2, '0')}${newG.toString(16).padStart(2, '0')}${newB.toString(16).padStart(2, '0')}`
    }
    return color
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['sceneId']) {
      this.sceneId = params['sceneId']
      
      const userScene = SceneStore.getSceneDetail(this.sceneId)
      if (userScene) {
        this.isUserScene = true
        this.userSceneData = userScene
        this.sceneData = this.convertToSceneDetailData(userScene)
      } else {
        this.isUserScene = false
        this.userSceneData = null
        this.sceneData = this.sceneDetails[this.sceneId] || null
      }
    }
  }

  private goBack(): void {
    console.log('返回按钮被点击');
    try {
      router.back();
    } catch (error) {
      console.error('返回失败，跳转到首页:', error);
      router.pushUrl({
        url: 'pages/Index'
      });
    }
  }

  private goToStore(): void {
    console.log('跳转到商城页面')
  }

  private getDeviceIsOn(deviceId: string): boolean {
    if (deviceId === 'light1') return this.lightOn
    if (deviceId === 'light2') return this.bedroomLightOn
    if (deviceId === 'light3') return this.kitchenLightOn
    if (deviceId === 'air') return this.airOn
    if (deviceId === 'heater') return this.heaterOn
    if (deviceId === 'door') return this.doorLocked
    if (deviceId === 'curtain') return this.curtainOpen
    if (deviceId === 'camera') return this.cameraOn
    if (deviceId === 'socket') return this.socketOn
    if (deviceId === 'tv') return this.tvOn
    if (deviceId === 'airPurifier') return this.airPurifierOn
    if (deviceId === 'robotVacuum') return this.robotVacuumOn
    if (deviceId === 'waterHeater') return this.waterHeaterOn
    if (deviceId === 'doorSensor') return this.doorSensorOn
    if (deviceId === 'bedsideLamp') return this.bedsideLampOn
    return false
  }

  private isActionSatisfied(item: SceneActionItem): boolean {
    if (!item.deviceId) return true
    const isOn = this.getDeviceIsOn(item.deviceId)
    if (item.action === 'on') return isOn
    if (item.action === 'off') return !isOn
    if (item.action === 'lock') return this.doorLocked
    if (item.action === 'unlock') return !this.doorLocked
    if (item.action === 'monitor') return isOn
    return false
  }

  private activateScene(): void {
    if (this.sceneData) {
      DeviceStore.triggerScene(this.sceneData.sceneId)
    }
  }

  private isSceneActive(): boolean {
    if (!this.sceneData) return false
    return this.activeScene === this.sceneData.sceneId
  }

  private editScene(): void {
    if (!this.isUserScene || !this.userSceneData) {
      console.error('无法编辑非用户场景')
      return
    }
    
    console.log('编辑场景:', this.sceneId)
    router.pushUrl({
      url: 'pages/SceneCreatePage',
      params: { sceneId: this.sceneId }
    })
  }

  private deleteScene(): void {
    if (!this.isUserScene || !this.userSceneData) {
      console.error('无法删除非用户场景')
      return
    }
    
    console.log('删除场景:', this.sceneId)
    SceneStore.deleteScene(this.sceneId)
    router.back()
  }

  @Builder TopGradientSection() {
    Column() {
      Row() {
      }
        .width('100%')
        .height(24)
        .backgroundColor('transparent')
      
      Row() {
        Row() {
          Text('←')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .fontWeight(500)
        }
          .width(40)
          .height(40)
          .borderRadius(BorderRadius.FULL)
          .backgroundColor('rgba(255, 255, 255, 0.3)')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .margin({ left: Spacing.LG })
          .onClick(() => {
            console.log('返回按钮点击事件触发');
            this.goBack();
          })

        Blank()
        
        Text(this.sceneData?.title || '场景详情')
          .fontSize(FontSize.TITLE2)
          .fontWeight(600)
          .fontColor('#FFFFFF')
        
        Blank()
        
        if (this.isUserScene) {
          Row({ space: Spacing.SM }) {
            Row() {
              Text('✎')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
              .width(40)
              .height(40)
              .borderRadius(BorderRadius.FULL)
              .backgroundColor('rgba(255, 255, 255, 0.3)')
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                console.log('编辑按钮点击事件触发')
                this.editScene()
              })
            
            Row() {
              Text('×')
                .fontSize(20)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
              .width(40)
              .height(40)
              .borderRadius(BorderRadius.FULL)
              .backgroundColor('rgba(255, 255, 255, 0.3)')
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                console.log('删除按钮点击事件触发')
                this.deleteScene()
              })
          }
          .margin({ right: Spacing.LG })
        } else {
          Row() {
          }
            .width(40)
            .height(40)
            .margin({ right: Spacing.LG })
        }
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      
      Column({ space: Spacing.SM }) {
        Text(this.sceneData?.title || '场景标题')
          .fontSize(32)
          .fontWeight(700)
          .fontColor('#FFFFFF')
          .margin({ left: Spacing.LG })
        
        Text(this.sceneData?.description || '场景描述')
          .fontSize(FontSize.BODY1)
          .fontColor('rgba(255, 255, 255, 0.9)')
          .margin({ left: Spacing.LG })
          .lineHeight(20)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(200)
    .backgroundColor(this.sceneData ? this.sceneData.gradientColors[0] : '#F5E6D3')
    .linearGradient({
      angle: 135,
      colors: this.sceneData ? [
        [this.sceneData.gradientColors[0], 0],
        [this.sceneData.gradientColors[1], 1]
      ] : [['#F5E6D3', 0], ['#D4B483', 1]]
    })
  }

  build() {
    Column() {
      this.TopGradientSection()
      
      Scroll() {
        Column({ space: Spacing.XL }) {
          if (this.sceneData && this.sceneData.triggerConditions.length > 0) {
            this.TriggerConditionsSection()
          }
          
          if (this.sceneData && this.sceneData.executionResults.length > 0) {
            this.ExecutionResultsSection()
          }
        }
        .width('100%')
        .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XL, top: Spacing.LG })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      if (this.sceneData) {
        Row() {
          Text(this.isSceneActive() ? '停止场景' : '启动场景')
            .fontSize(FontSize.BODY1)
            .fontWeight(600)
            .fontColor('#FFFFFF')
        }
        .width('90%')
        .height(48)
        .justifyContent(FlexAlign.Center)
        .borderRadius(24)
        .backgroundColor(this.isSceneActive() ? Colors.WARNING : Colors.BRAND_PRIMARY)
        .margin({ bottom: Spacing.XXL })
        .onClick(() => {
          this.activateScene()
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }

  @Builder TriggerConditionsSection() {
    Column({ space: Spacing.MD }) {
      Text('启动条件')
        .fontSize(FontSize.BODY1)
        .fontWeight(500)
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .alignSelf(ItemAlign.Start)
      
      Column({ space: Spacing.SM }) {
        ForEach(this.sceneData?.triggerConditions || [], (item: SceneActionItem) => {
          this.ActionCard(item)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder ExecutionResultsSection() {
    Column({ space: Spacing.MD }) {
      Text('执行结果')
        .fontSize(FontSize.BODY1)
        .fontWeight(500)
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .alignSelf(ItemAlign.Start)
      
      Column({ space: Spacing.SM }) {
        ForEach(this.sceneData?.executionResults || [], (item: SceneActionItem) => {
          this.ActionCard(item)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder ActionCard(item: SceneActionItem) {
    Row({ space: Spacing.MD }) {
      Text(item.icon)
        .fontSize(24)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .margin({ left: Spacing.MD })
      
      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(FontSize.BODY1)
          .fontWeight(500)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .textAlign(TextAlign.Start)
        
        Text(item.description)
          .fontSize(FontSize.CAPTION1)
          .fontColor(ThemeColors.textSecondary(this.isDark))
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      
      if (item.deviceId) {
        Text(this.isActionSatisfied(item) ? '✓' : '待执行')
          .fontSize(FontSize.CAPTION1)
          .fontWeight(500)
          .fontColor(this.isActionSatisfied(item) ? Colors.SUCCESS : ThemeColors.textTertiary(this.isDark))
          .margin({ right: Spacing.MD })
      }
    }
    .width('100%')
    .height(72)
    .borderRadius(16)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: 4,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 2
    })
  }
}
