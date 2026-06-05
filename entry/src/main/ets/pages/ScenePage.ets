/**
 * 场景中心页 - 场景列表 + 场景编辑
 * 基于 HarmonyOS Design 规范实现
 */
import { DeviceStore } from '../DeviceStore'
import { Colors, FontSize, Spacing, BorderRadius, GlowConfig } from '../common/DesignConstants'
import { HaloButton } from '../components/HaloButton'
import { SceneCard, SceneModel } from '../components/SceneCard'

// 场景动作类型
interface SceneAction {
  deviceId: string
  deviceName: string
  action: string
  value?: string
}

// 场景触发条件
interface SceneTrigger {
  type: 'time' | 'device' | 'manual'
  condition?: string
}

// 完整场景模型
interface FullSceneModel extends SceneModel {
  description: string
  trigger: SceneTrigger
  actions: SceneAction[]
}

@Component
export struct ScenePage {
  // 场景列表
  @State private scenes: FullSceneModel[] = [
    {
      id: 'home',
      name: '回家模式',
      icon: '🏠',
      color: '#007DFF',
      isActive: false,
      deviceCount: 5,
      description: '回家后一键开启常用设备',
      trigger: { type: 'manual' } as SceneTrigger,
      actions: [
        { deviceId: 'light', deviceName: '客厅灯', action: 'turnOn', value: '80%' } as SceneAction,
        { deviceId: 'air', deviceName: '空调', action: 'turnOn', value: '26℃' } as SceneAction,
        { deviceId: 'curtain', deviceName: '窗帘', action: 'open' } as SceneAction
      ]
    } as FullSceneModel,
    {
      id: 'leave',
      name: '离家模式',
      icon: '🚶',
      color: '#00A5FF',
      isActive: false,
      deviceCount: 8,
      description: '关闭设备并锁门',
      trigger: { type: 'manual' } as SceneTrigger,
      actions: [
        { deviceId: 'light', deviceName: '所有灯', action: 'turnOff' } as SceneAction,
        { deviceId: 'air', deviceName: '空调', action: 'turnOff' } as SceneAction,
        { deviceId: 'door', deviceName: '门锁', action: 'lock' } as SceneAction
      ]
    } as FullSceneModel,
    {
      id: 'sleep',
      name: '睡眠模式',
      icon: '🌙',
      color: '#6B7280',
      isActive: false,
      deviceCount: 4,
      description: '自动进入夜间状态',
      trigger: { type: 'time', condition: '22:00' } as SceneTrigger,
      actions: [
        { deviceId: 'light', deviceName: '所有灯', action: 'turnOff' } as SceneAction,
        { deviceId: 'air', deviceName: '空调', action: 'turnOn', value: '24℃' } as SceneAction,
        { deviceId: 'curtain', deviceName: '窗帘', action: 'close' } as SceneAction
      ]
    } as FullSceneModel,
    {
      id: 'movie',
      name: '观影模式',
      icon: '🎬',
      color: '#8B5CF6',
      isActive: false,
      deviceCount: 3,
      description: '营造家庭影院环境',
      trigger: { type: 'manual' } as SceneTrigger,
      actions: [
        { deviceId: 'light', deviceName: '客厅灯', action: 'turnOn', value: '20%' } as SceneAction,
        { deviceId: 'curtain', deviceName: '窗帘', action: 'close' } as SceneAction
      ]
    } as FullSceneModel,
    {
      id: 'reading',
      name: '阅读模式',
      icon: '📖',
      color: '#FFB800',
      isActive: false,
      deviceCount: 2,
      description: '舒适的阅读环境',
      trigger: { type: 'manual' } as SceneTrigger,
      actions: [
        { deviceId: 'light', deviceName: '台灯', action: 'turnOn', value: '100%' } as SceneAction
      ]
    } as FullSceneModel
  ]
  
  // 当前选中的场景（用于编辑）
  @State private selectedScene: FullSceneModel | null = null
  @State private showEditor: boolean = false
  
  // 执行场景
  private executeScene(sceneId: string) {
    // 更新场景激活状态
    this.scenes = this.scenes.map(scene => {
      return {
        id: scene.id,
        name: scene.name,
        icon: scene.icon,
        color: scene.color,
        isActive: scene.id === sceneId,
        deviceCount: scene.deviceCount,
        description: scene.description,
        trigger: scene.trigger,
        actions: scene.actions
      } as FullSceneModel
    })
    
    // 执行场景动作
    const scene = this.scenes.find(s => s.id === sceneId)
    if (!scene) return
    
    // 根据场景执行设备操作
    if (sceneId === 'home') {
      DeviceStore.setLightOn(true)
      DeviceStore.setAirOn(true)
      DeviceStore.setCurtainOpen(true)
    } else if (sceneId === 'leave') {
      DeviceStore.setLightOn(false)
      DeviceStore.setAirOn(false)
      DeviceStore.setSocketOn(false)
      DeviceStore.setDoorLocked(true)
    } else if (sceneId === 'sleep') {
      DeviceStore.setLightOn(false)
      DeviceStore.setAirOn(true)
      DeviceStore.setDoorLocked(true)
    } else if (sceneId === 'movie') {
      DeviceStore.setLightOn(false)
      DeviceStore.setCurtainOpen(false)
    }
    
    // 显示执行提示
    AlertDialog.show({
      title: scene.name,
      message: `已执行 ${scene.actions.length} 个设备操作`,
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: -100 }
    })
  }
  
  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar()
      
      Scroll() {
        Column({ space: Spacing.XL }) {
          // 推荐场景
          this.RecommendSection()
          
          // 我的场景
          this.MyScenesSection()
          
          // 自动化场景
          this.AutomationSection()
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
      Text('场景中心')
        .fontSize(FontSize.TITLE1)
        .fontWeight(700)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      
      Blank()
      
      // 添加场景按钮
      Row({ space: 4 }) {
        Text('+')
          .fontSize(24)
          .fontColor(Colors.BRAND_PRIMARY)
        
        Text('创建')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(BorderRadius.MEDIUM)
      .backgroundColor(Colors.BRAND_PRIMARY + '10')
      .onClick(() => {
        // TODO: 打开场景编辑器
        this.showEditor = true
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 推荐场景
  @Builder RecommendSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('🌟')
          .fontSize(20)
        
        Text('推荐场景')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      .width('100%')
      
      // 推荐场景卡片
      Row({ space: Spacing.SM }) {
        ForEach(this.scenes.slice(0, 2), (scene: FullSceneModel) => {
          Column({ space: 8 }) {
            Text(scene.icon)
              .fontSize(48)
            
            Text(scene.name)
              .fontSize(FontSize.BODY1)
              .fontWeight(600)
              .fontColor(Colors.TEXT_PRIMARY_LIGHT)
            
            Text(scene.description)
              .fontSize(FontSize.CAPTION1)
              .fontColor(Colors.TEXT_SECONDARY_LIGHT)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('48%')
          .padding(Spacing.LG)
          .borderRadius(BorderRadius.LARGE)
          .backgroundColor(Colors.SURFACE_LIGHT)
          .shadow({
            radius: scene.isActive ? 16 : 4,
            color: scene.isActive ? scene.color + '40' : '#1A000000',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => {
            this.executeScene(scene.id)
          })
        })
      }
      .width('100%')
    }
    .width('100%')
  }
  
  // 我的场景
  @Builder MyScenesSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('📋')
          .fontSize(20)
        
        Text('我的场景')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Blank()
        
        Text('管理 >')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
      }
      .width('100%')
      
      // 场景网格
      Grid() {
        ForEach(this.scenes, (scene: FullSceneModel) => {
          GridItem() {
            SceneCard({
              scene: scene,
              onTap: () => {
                this.executeScene(scene.id)
              }
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(Spacing.MD)
      .columnsGap(Spacing.SM)
      .width('100%')
      .height(160)
    }
    .width('100%')
  }
  
  // 自动化场景
  @Builder AutomationSection() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('⏰')
          .fontSize(20)
        
        Text('自动化')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Blank()
        
        HaloButton({
          label: '添加',
          buttonSize: 'small',
          type: 'outline'
        })
      }
      .width('100%')
      
      // 自动化场景列表
      Column({ space: Spacing.SM }) {
        this.AutomationItem('睡眠模式', '每天 22:00 自动执行', true)
        this.AutomationItem('起床模式', '每天 07:00 自动执行', false)
        this.AutomationItem('回家模式', '距离家 100米时自动执行', true)
      }
      .width('100%')
    }
    .width('100%')
  }
  
  // 自动化场景项
  @Builder AutomationItem(name: string, condition: string, enabled: boolean) {
    Row() {
      Column({ space: 4 }) {
        Text(name)
          .fontSize(FontSize.BODY1)
          .fontWeight(500)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        
        Text(condition)
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      // 使用简化的 Toggle 组件
      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .enabled(true)
    }
    .width('100%')
    .padding(Spacing.MD)
    .borderRadius(BorderRadius.MEDIUM)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
}
