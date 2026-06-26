/**
 * 场景详情页
 * 统一结构：顶部状态栏 + 返回箭头 + 场景标题 + 描述 + 渐变背景
 * 中间分「启动条件」和「执行结果」两个模块，每个模块下是白色圆角卡片列表
 * 底部无导航栏，仅保留返回逻辑
 */
import { Colors, FontSize, Spacing, BorderRadius } from '../common/DesignConstants'
import router from '@ohos.router'
import { SceneStore, SceneModel } from '../SceneStore'

// 场景条件/结果项类型
export interface SceneActionItem {
  id: string
  icon: string
  title: string
  description: string
  hasPurchaseButton: boolean  // 是否有购买按钮
}

// 场景详情数据类型
export interface SceneDetailData {
  id: string
  title: string
  description: string
  gradientColors: string[]  // [start, end]
  triggerConditions: SceneActionItem[]  // 启动条件
  executionResults: SceneActionItem[]    // 执行结果
}

@Entry
@Component
export struct SceneDetailPage {
  // 路由参数
  @State private sceneId: string = ''
  @State private sceneData: SceneDetailData | null = null
  @State private isUserScene: boolean = false
  @State private userSceneData: SceneModel | null = null

  // 场景数据配置
  private readonly sceneDetails: Record<string, SceneDetailData> = {
    'leave_home': {
      id: 'leave_home',
      title: '安心离家',
      description: '离开家后，自动关闭空调、灯、开关，开启空气净化器等',
      gradientColors: ['#F5E6D3', '#D4B483'],
      triggerConditions: [
        {
          id: 'location',
          icon: '📍',
          title: '离开某地',
          description: '',
          hasPurchaseButton: false
        }
      ],
      executionResults: [
        {
          id: 'switch',
          icon: '🔌',
          title: '开关',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'light',
          icon: '💡',
          title: '灯',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'ac',
          icon: '❄️',
          title: '空调',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'air_purifier',
          icon: '💨',
          title: '空气净化器',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        }
      ]
    },
    'alert': {
      id: 'alert',
      title: '异常警报',
      description: '当传感器设备检测到异常时会向您推送通知',
      gradientColors: ['#FFD8CC', '#FF9A7A'],
      triggerConditions: [
        {
          id: 'door_sensor',
          icon: '🚪',
          title: '门磁传感器',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        }
      ],
      executionResults: [
        {
          id: 'notification',
          icon: '🔔',
          title: '推送通知',
          description: '将给您发送您输入的自定义内容',
          hasPurchaseButton: false
        }
      ]
    },
    'morning': {
      id: 'morning',
      title: '早起习惯',
      description: '早晨自动开启灯、空气净化器，关闭空调等，减少起床阻力',
      gradientColors: ['#FFF9E6', '#FFE699'],
      triggerConditions: [
        {
          id: 'timer',
          icon: '⏰',
          title: '定时',
          description: '',
          hasPurchaseButton: false
        }
      ],
      executionResults: [
        {
          id: 'light',
          icon: '💡',
          title: '灯',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'ac',
          icon: '❄️',
          title: '空调',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'air_purifier',
          icon: '💨',
          title: '空气净化器',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        }
      ]
    },
    'sleep': {
      id: 'sleep',
      title: '就寝提醒',
      description: '为你提供适合睡眠的环境，自动开启空调、空气净化器，关闭灯、插座、开关等',
      gradientColors: ['#E8D9C5', '#B89B7D'],
      triggerConditions: [
        {
          id: 'timer',
          icon: '⏰',
          title: '定时',
          description: '',
          hasPurchaseButton: false
        }
      ],
      executionResults: [
        {
          id: 'light',
          icon: '💡',
          title: '灯',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'socket',
          icon: '🔌',
          title: '插座',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'switch',
          icon: '🔌',
          title: '开关',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'air_purifier',
          icon: '💨',
          title: '空气净化器',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'ac',
          icon: '❄️',
          title: '空调',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'bedside_lamp',
          icon: '💡',
          title: '台灯',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        }
      ]
    },
    'back_home': {
      id: 'back_home',
      title: '温馨回家',
      description: '回到家后，一键开启空调、灯、热水器，关闭扫地机器人、空气净化器等',
      gradientColors: ['#F0F0F0', '#D9D9D9'],
      triggerConditions: [],  // 无启动条件
      executionResults: [
        {
          id: 'air_purifier',
          icon: '💨',
          title: '空气净化器',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'robot_vacuum',
          icon: '🤖',
          title: '扫地机器人',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'light',
          icon: '💡',
          title: '灯',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'switch',
          icon: '🔌',
          title: '开关',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'water_heater',
          icon: '♨️',
          title: '热水器',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        },
        {
          id: 'ac',
          icon: '❄️',
          title: '空调',
          description: '暂无设备，去商城看看',
          hasPurchaseButton: true
        }
      ]
    }
  }

  // 将 SceneModel 转换为 SceneDetailData
  private convertToSceneDetailData(scene: SceneModel): SceneDetailData {
    // 将触发条件字符串转换为 SceneActionItem 数组
    const triggerConditionItem = {
      id: scene.triggerCondition,
      icon: this.getTriggerIcon(scene.triggerCondition),
      title: SceneStore.getTriggerConditionName(scene.triggerCondition),
      description: this.getTriggerDescription(scene.triggerCondition),
      hasPurchaseButton: false
    } as SceneActionItem

    // 将动作数组转换为 SceneActionItem 数组
    const executionResults = scene.actions.map(actionId => ({
      id: actionId,
      icon: SceneStore.getActionIcon(actionId),
      title: SceneStore.getActionName(actionId),
      description: this.getActionDescription(actionId),
      hasPurchaseButton: false
    } as SceneActionItem))

    return {
      id: scene.id,
      title: scene.name,
      description: scene.description || '暂无描述',
      gradientColors: [scene.color, this.adjustColorBrightness(scene.color, 0.8)], // 生成渐变颜色
      triggerConditions: [triggerConditionItem],
      executionResults: executionResults
    }
  }

  // 获取触发条件图标
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

  // 获取触发条件描述
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

  // 获取动作描述
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

  // 调整颜色亮度
  private adjustColorBrightness(color: string, factor: number): string {
    // 简单实现：假设颜色是 #RRGGBB 格式
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
    // 从路由参数获取场景ID
    const params = router.getParams() as Record<string, string>
    if (params && params['sceneId']) {
      this.sceneId = params['sceneId']
      
      // 首先尝试从 SceneStore 加载用户场景
      const userScene = SceneStore.getSceneDetail(this.sceneId)
      if (userScene) {
        this.isUserScene = true
        this.userSceneData = userScene
        // 将 SceneModel 转换为 SceneDetailData
        this.sceneData = this.convertToSceneDetailData(userScene)
      } else {
        // 使用硬编码的场景数据
        this.isUserScene = false
        this.userSceneData = null
        this.sceneData = this.sceneDetails[this.sceneId] || null
      }
    }
  }

  // 返回上一页
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

  // 跳转到商城页面
  private goToStore(): void {
    // TODO: 跳转到商城页面
    console.log('跳转到商城页面')
  }

  // 编辑场景
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

  // 删除场景
  private deleteScene(): void {
    if (!this.isUserScene || !this.userSceneData) {
      console.error('无法删除非用户场景')
      return
    }
    
    console.log('删除场景:', this.sceneId)
    // 从 SceneStore 中删除
    SceneStore.deleteScene(this.sceneId)
    // 返回上一页
    router.back()
  }

  // 顶部渐变区域（包含状态栏占位、导航栏、标题和描述）
  @Builder TopGradientSection() {
    Column() {
      // 状态栏占位（渐变背景）
      Row() {
      }
        .width('100%')
        .height(24)
        .backgroundColor('transparent')
      
      // 导航栏（返回箭头 + 页面标题）
      Row() {
        // 返回按钮
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
        
        // 页面标题
        Text(this.sceneData?.title || '场景详情')
          .fontSize(FontSize.TITLE2)
          .fontWeight(600)
          .fontColor('#FFFFFF')
        
        Blank()
        
        // 右侧按钮区域
        if (this.isUserScene) {
          Row({ space: Spacing.SM }) {
            // 编辑按钮
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
            
            // 删除按钮
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
          // 非用户场景保持空白占位
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
      
      // 标题和描述区域（垂直居中）
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
      .layoutWeight(1) // 占据剩余空间
      .justifyContent(FlexAlign.Center) // 垂直居中
    }
    .width('100%')
    .height(200) // 固定高度
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
      // 顶部渐变区域（包含状态栏占位、导航栏、标题和描述）
      this.TopGradientSection()
      
      Scroll() {
        Column({ space: Spacing.XL }) {
          // 启动条件模块
          if (this.sceneData && this.sceneData.triggerConditions.length > 0) {
            this.TriggerConditionsSection()
          }
          
          // 执行结果模块
          if (this.sceneData && this.sceneData.executionResults.length > 0) {
            this.ExecutionResultsSection()
          }
        }
        .width('100%')
        .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XXL, top: Spacing.LG })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA') // 极浅灰白色背景
  }



  // 启动条件模块
  @Builder TriggerConditionsSection() {
    Column({ space: Spacing.MD }) {
      // 模块标题
      Text('启动条件')
        .fontSize(FontSize.BODY1)
        .fontWeight(500)
        .fontColor('#666666')
        .alignSelf(ItemAlign.Start)
      
      // 条件卡片列表
      Column({ space: Spacing.SM }) {
        ForEach(this.sceneData?.triggerConditions || [], (item: SceneActionItem) => {
          this.ActionCard(item)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // 执行结果模块
  @Builder ExecutionResultsSection() {
    Column({ space: Spacing.MD }) {
      // 模块标题
      Text('执行结果')
        .fontSize(FontSize.BODY1)
        .fontWeight(500)
        .fontColor('#666666')
        .alignSelf(ItemAlign.Start)
      
      // 结果卡片列表
      Column({ space: Spacing.SM }) {
        ForEach(this.sceneData?.executionResults || [], (item: SceneActionItem) => {
          this.ActionCard(item)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // 动作卡片（通用，用于启动条件和执行结果）
  @Builder ActionCard(item: SceneActionItem) {
    Row({ space: Spacing.MD }) {
      // 图标
      Text(item.icon)
        .fontSize(24)
        .fontColor('#000000')
        .margin({ left: Spacing.MD })
      
      // 文字区域
      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(FontSize.BODY1)
          .fontWeight(500)
          .fontColor('#000000')
          .textAlign(TextAlign.Start)
        
        if (item.description) {
          Text(item.description)
            .fontSize(FontSize.CAPTION1)
            .fontColor('#666666')
            .textAlign(TextAlign.Start)
        }
      }
      .layoutWeight(1)
      
      // 购买按钮（如果有）
      if (item.hasPurchaseButton) {
        Text('购买')
          .fontSize(FontSize.CAPTION1)
          .fontWeight(500)
          .fontColor('#00C1B3') // 蓝绿色
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .border({
            width: 1,
            color: '#00C1B3',
            style: BorderStyle.Solid
          })
          .margin({ right: Spacing.MD })
          .onClick(() => {
            this.goToStore()
          })
      }
    }
    .width('100%')
    .height(72)
    .borderRadius(16)
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}