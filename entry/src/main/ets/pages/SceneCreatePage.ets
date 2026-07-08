/**
 * 场景创建/编辑页面
 * 用于创建新场景或编辑现有场景
 */
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import router from '@ohos.router'
import { SceneStore, SceneModel } from '../SceneStore'

interface TriggerCondition {
  id: string
  name: string
  icon: string
  description: string
}

interface ExecutionAction {
  id: string
  name: string
  icon: string
  description: string
  deviceType: string
}

@Entry
@Component
export struct SceneCreatePage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @State private sceneId: string = ''
  @State private isEditing: boolean = false
  @State private sceneName: string = ''
  @State private sceneDescription: string = ''
  @State private selectedTrigger: string = ''
  @State private selectedActions: string[] = []
  
  private readonly triggerOptions: TriggerCondition[] = [
    { id: 'leave_location', name: '离开某地', icon: '📍', description: '离开指定地理位置时触发' },
    { id: 'arrive_location', name: '到达某地', icon: '📍', description: '到达指定地理位置时触发' },
    { id: 'time_schedule', name: '定时', icon: '⏰', description: '按时间计划触发' },
    { id: 'device_status', name: '设备状态', icon: '📱', description: '设备状态变化时触发' },
    { id: 'weather', name: '天气条件', icon: '☁️', description: '特定天气条件时触发' },
    { id: 'manual', name: '手动触发', icon: '👆', description: '手动点击触发' }
  ]
  
  private readonly actionOptions: ExecutionAction[] = [
    { id: 'turn_on_light', name: '打开灯', icon: '💡', description: '打开指定灯光', deviceType: 'light' },
    { id: 'turn_off_light', name: '关闭灯', icon: '💡', description: '关闭指定灯光', deviceType: 'light' },
    { id: 'turn_on_ac', name: '打开空调', icon: '❄️', description: '打开空调并设置温度', deviceType: 'air_conditioner' },
    { id: 'turn_off_ac', name: '关闭空调', icon: '❄️', description: '关闭空调', deviceType: 'air_conditioner' },
    { id: 'lock_door', name: '锁门', icon: '🔒', description: '锁定智能门锁', deviceType: 'door_lock' },
    { id: 'unlock_door', name: '开门', icon: '🔓', description: '解锁智能门锁', deviceType: 'door_lock' },
    { id: 'close_curtain', name: '关闭窗帘', icon: '🪟', description: '关闭智能窗帘', deviceType: 'curtain' },
    { id: 'open_curtain', name: '打开窗帘', icon: '🪟', description: '打开智能窗帘', deviceType: 'curtain' },
    { id: 'turn_on_socket', name: '打开插座', icon: '🔌', description: '打开智能插座电源', deviceType: 'socket' },
    { id: 'turn_off_socket', name: '关闭插座', icon: '🔌', description: '关闭智能插座电源', deviceType: 'socket' }
  ]

  aboutToAppear(): void {
    const params = router.getParams()
    if (params) {
      this.sceneId = (params as Record<string, string>).sceneId || ''
      this.isEditing = !!this.sceneId
      
      if (this.isEditing) {
        this.loadSceneData()
      }
    }
  }

  private loadSceneData(): void {
    console.log('加载场景数据:', this.sceneId)
    const sceneData = SceneStore.getSceneDetail(this.sceneId)
    
    if (sceneData) {
      this.sceneName = sceneData.name
      this.sceneDescription = sceneData.description
      this.selectedTrigger = sceneData.triggerCondition
      this.selectedActions = [...sceneData.actions]
    } else {
      console.warn('未找到场景数据:', this.sceneId)
      this.sceneName = '我的场景'
      this.sceneDescription = '这是一个示例场景描述'
      this.selectedTrigger = 'leave_location'
      this.selectedActions = ['turn_off_light', 'turn_off_ac', 'lock_door']
    }
  }

  private goBack(): void {
    console.log('取消创建/编辑场景')
    router.back()
  }

  private saveScene(): void {
    if (!this.sceneName.trim()) {
      console.error('场景名称不能为空')
      return
    }

    if (!this.selectedTrigger) {
      console.error('请选择触发条件')
      return
    }

    if (this.selectedActions.length === 0) {
      console.error('请至少选择一个执行动作')
      return
    }

    let originalScene: SceneModel | null = null
    if (this.isEditing) {
      originalScene = SceneStore.getSceneDetail(this.sceneId)
    }

    const sceneData: SceneModel = {
      id: this.isEditing ? this.sceneId : `scene_${Date.now()}`,
      name: this.sceneName.trim(),
      description: this.sceneDescription.trim(),
      triggerCondition: this.selectedTrigger,
      actions: [...this.selectedActions],
      icon: '🏠',
      color: Colors.BRAND_PRIMARY,
      isActive: true,
      deviceCount: this.selectedActions.length,
      createdAt: originalScene?.createdAt || new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }

    console.log('保存场景数据:', sceneData)
    SceneStore.saveScene(sceneData)
    router.back()
  }

  private toggleAction(actionId: string): void {
    const index = this.selectedActions.indexOf(actionId)
    if (index === -1) {
      this.selectedActions.push(actionId)
    } else {
      this.selectedActions.splice(index, 1)
    }
    this.selectedActions = [...this.selectedActions]
  }

  @Builder TopBar() {
    Row() {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width(40)
      .height(40)
      .borderRadius(BorderRadius.FULL)
      .backgroundColor(this.isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ left: Spacing.LG })
      .onClick(() => {
        this.goBack()
      })

      Blank()

      Text(this.isEditing ? '编辑场景' : '创建场景')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))

      Blank()

      Text('保存')
        .fontSize(FontSize.BODY1)
        .fontWeight(500)
        .fontColor(Colors.BRAND_PRIMARY)
        .margin({ right: Spacing.LG })
        .onClick(() => {
          this.saveScene()
        })
    }
    .width('100%')
    .height(56)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      this.TopBar()

      Scroll() {
        Column({ space: Spacing.XL }) {
          Column({ space: Spacing.SM }) {
            Text('场景名称')
              .fontSize(FontSize.BODY1)
              .fontWeight(500)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .alignSelf(ItemAlign.Start)
            
            TextInput({ placeholder: '请输入场景名称，如"安心离家"' })
              .width('100%')
              .height(48)
              .padding({ left: Spacing.MD, right: Spacing.MD })
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(ThemeColors.itemBg(this.isDark))
              .fontSize(FontSize.BODY1)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .onChange((value: string) => {
                this.sceneName = value
              })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG })

          Column({ space: Spacing.SM }) {
            Text('场景描述')
              .fontSize(FontSize.BODY1)
              .fontWeight(500)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .alignSelf(ItemAlign.Start)
            
            TextInput({ placeholder: '请输入场景描述（可选）' })
              .width('100%')
              .height(80)
              .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.MD, bottom: Spacing.MD })
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(ThemeColors.itemBg(this.isDark))
              .fontSize(FontSize.BODY1)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .maxLines(3)
              .onChange((value: string) => {
                this.sceneDescription = value
              })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG })

          Column({ space: Spacing.SM }) {
            Text('触发条件')
              .fontSize(FontSize.BODY1)
              .fontWeight(500)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .alignSelf(ItemAlign.Start)
            
            Text('选择场景的触发条件')
              .fontSize(FontSize.CAPTION1)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .alignSelf(ItemAlign.Start)
            
            Column({ space: Spacing.XS }) {
              ForEach(this.triggerOptions, (trigger: TriggerCondition) => {
                Row() {
                  Text(trigger.icon)
                    .fontSize(20)
                    .margin({ right: Spacing.MD })
                  
                  Column({ space: 2 }) {
                    Text(trigger.name)
                      .fontSize(FontSize.BODY1)
                      .fontColor(ThemeColors.textPrimary(this.isDark))
                    
                    Text(trigger.description)
                      .fontSize(FontSize.CAPTION2)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  
                  Row() {
                    if (this.selectedTrigger === trigger.id) {
                      Circle({ width: 10, height: 10 })
                        .fill(Colors.BRAND_PRIMARY)
                    }
                  }
                  .width(20)
                  .height(20)
                  .borderRadius(BorderRadius.FULL)
                  .border({ width: 2, color: this.selectedTrigger === trigger.id ? Colors.BRAND_PRIMARY : (this.isDark ? '#555555' : '#CCCCCC') })
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .height(60)
                .padding({ left: Spacing.MD, right: Spacing.MD })
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(this.selectedTrigger === trigger.id ? ThemeColors.selectedBg(this.isDark) : ThemeColors.surface(this.isDark))
                .border({ width: 1, color: this.selectedTrigger === trigger.id ? Colors.BRAND_PRIMARY : (this.isDark ? '#3A3A3A' : '#EEEEEE') })
                .onClick(() => {
                  this.selectedTrigger = trigger.id
                })
              })
            }
            .width('100%')
            .margin({ top: Spacing.SM })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG })

          Column({ space: Spacing.SM }) {
            Text('执行动作')
              .fontSize(FontSize.BODY1)
              .fontWeight(500)
              .fontColor(ThemeColors.textPrimary(this.isDark))
              .alignSelf(ItemAlign.Start)
            
            Text('选择场景触发后要执行的动作')
              .fontSize(FontSize.CAPTION1)
              .fontColor(ThemeColors.textSecondary(this.isDark))
              .alignSelf(ItemAlign.Start)
            
            Column({ space: Spacing.XS }) {
              ForEach(this.actionOptions, (action: ExecutionAction) => {
                Row() {
                  Text(action.icon)
                    .fontSize(20)
                    .margin({ right: Spacing.MD })
                  
                  Column({ space: 2 }) {
                    Text(action.name)
                      .fontSize(FontSize.BODY1)
                      .fontColor(ThemeColors.textPrimary(this.isDark))
                    
                    Text(action.description)
                      .fontSize(FontSize.CAPTION2)
                      .fontColor(ThemeColors.textSecondary(this.isDark))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  
                  Row() {
                    if (this.selectedActions.includes(action.id)) {
                      Text('✓')
                        .fontSize(14)
                        .fontColor('#FFFFFF')
                    }
                  }
                  .width(20)
                  .height(20)
                  .borderRadius(BorderRadius.SMALL)
                  .backgroundColor(this.selectedActions.includes(action.id) ? Colors.BRAND_PRIMARY : ThemeColors.surface(this.isDark))
                  .border({ width: 1, color: this.selectedActions.includes(action.id) ? Colors.BRAND_PRIMARY : (this.isDark ? '#555555' : '#CCCCCC') })
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .height(60)
                .padding({ left: Spacing.MD, right: Spacing.MD })
                .borderRadius(BorderRadius.MEDIUM)
                .backgroundColor(this.selectedActions.includes(action.id) ? ThemeColors.selectedBg(this.isDark) : ThemeColors.surface(this.isDark))
                .border({ width: 1, color: this.selectedActions.includes(action.id) ? Colors.BRAND_PRIMARY : (this.isDark ? '#3A3A3A' : '#EEEEEE') })
                .onClick(() => {
                  this.toggleAction(action.id)
                })
              })
            }
            .width('100%')
            .margin({ top: Spacing.SM })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XXL })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
