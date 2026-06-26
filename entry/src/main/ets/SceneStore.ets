/**
 * 场景状态管理 - 使用 AppStorage 实现全局响应式状态
 * 所有页面通过 @StorageLink 自动同步状态变化
 */
import { Colors } from './common/DesignConstants'

// 场景数据模型
export interface SceneModel {
  id: string
  name: string
  description: string
  icon: string
  color: string
  isActive: boolean
  deviceCount: number
  triggerCondition: string
  actions: string[]
  createdAt: string
  updatedAt: string
}

export class SceneStore {
  // 初始化全局状态到 AppStorage
  static initialize(): void {
    // 用户创建的场景列表
    if (!AppStorage.has('userScenes')) {
      AppStorage.setOrCreate('userScenes', [])
    }
    
    // 场景详情数据映射
    if (!AppStorage.has('sceneDetails')) {
      AppStorage.setOrCreate('sceneDetails', {
        // 默认场景数据
        'device_linkage': {
          id: 'device_linkage',
          name: '设备联动变场景',
          description: '离家放心，归家省心',
          icon: '🏠',
          color: Colors.BRAND_PRIMARY,
          isActive: true,
          deviceCount: 3,
          triggerCondition: 'manual',
          actions: ['turn_off_light', 'turn_off_ac', 'lock_door'],
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z'
        }
      })
    }
  }

  // 获取用户创建的所有场景
  static getUserScenes(): SceneModel[] {
    const scenes = AppStorage.get<SceneModel[]>('userScenes') || []
    return [...scenes]
  }

  // 获取场景详情
  static getSceneDetail(sceneId: string): SceneModel | null {
    const details = AppStorage.get<Record<string, SceneModel>>('sceneDetails') || {}
    return details[sceneId] || null
  }

  // 保存场景（创建或更新）
  static saveScene(scene: SceneModel): void {
    // 获取当前数据
    const userScenes = AppStorage.get<SceneModel[]>('userScenes') || []
    const sceneDetails = AppStorage.get<Record<string, SceneModel>>('sceneDetails') || {}
    
    const existingIndex = userScenes.findIndex(s => s.id === scene.id)
    
    if (existingIndex >= 0) {
      // 更新现有场景
      userScenes[existingIndex] = scene
    } else {
      // 添加新场景
      userScenes.push(scene)
    }
    
    // 更新详情映射
    sceneDetails[scene.id] = scene
    
    // 保存回 AppStorage
    AppStorage.set('userScenes', userScenes.concat())
    const newDetails: Record<string, SceneModel> = {}
    const keys = Object.keys(sceneDetails)
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i]
      newDetails[key] = sceneDetails[key]
    }
    AppStorage.set('sceneDetails', newDetails)
    
    console.log('场景保存成功:', scene.id)
  }

  // 删除场景
  static deleteScene(sceneId: string): void {
    // 获取当前数据
    const userScenes = AppStorage.get<SceneModel[]>('userScenes') || []
    const sceneDetails = AppStorage.get<Record<string, SceneModel>>('sceneDetails') || {}
    
    // 从用户场景列表中移除
    const filteredScenes = userScenes.filter(scene => scene.id !== sceneId)
    
    // 从详情映射中移除
    const remainingDetails: Record<string, SceneModel> = {}
    const keys = Object.keys(sceneDetails)
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i]
      if (key !== sceneId) {
        remainingDetails[key] = sceneDetails[key]
      }
    }
    
    // 保存回 AppStorage
    AppStorage.set('userScenes', filteredScenes)
    AppStorage.set('sceneDetails', remainingDetails)
    
    console.log('场景删除成功:', sceneId)
  }

  // 切换场景激活状态
  static toggleSceneActive(sceneId: string): void {
    const sceneDetails = AppStorage.get<Record<string, SceneModel>>('sceneDetails') || {}
    const scene = sceneDetails[sceneId]
    
    if (scene) {
      const updatedScene: SceneModel = {
        id: scene.id,
        name: scene.name,
        description: scene.description,
        icon: scene.icon,
        color: scene.color,
        isActive: !scene.isActive,
        deviceCount: scene.deviceCount,
        triggerCondition: scene.triggerCondition,
        actions: scene.actions,
        createdAt: scene.createdAt,
        updatedAt: new Date().toISOString()
      }
      
      sceneDetails[sceneId] = updatedScene
      const newDetails: Record<string, SceneModel> = {}
      const keys = Object.keys(sceneDetails)
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i]
        newDetails[key] = sceneDetails[key]
      }
      AppStorage.set('sceneDetails', newDetails)
      
      // 同时更新用户场景列表中的状态
      const userScenes = AppStorage.get<SceneModel[]>('userScenes') || []
      const updatedUserScenes = userScenes.map(s => 
        s.id === sceneId ? updatedScene : s
      )
      AppStorage.set('userScenes', updatedUserScenes)
      
      console.log('场景状态切换:', sceneId, '->', updatedScene.isActive)
    }
  }

  // 获取触发条件名称
  static getTriggerConditionName(triggerId: string): string {
    const triggerMap: Record<string, string> = {
      'leave_location': '离开某地',
      'arrive_location': '到达某地',
      'time_schedule': '定时',
      'device_status': '设备状态',
      'weather': '天气条件',
      'manual': '手动触发'
    }
    return triggerMap[triggerId] || '未知触发条件'
  }

  // 获取动作名称
  static getActionName(actionId: string): string {
    const actionMap: Record<string, string> = {
      'turn_on_light': '打开灯',
      'turn_off_light': '关闭灯',
      'turn_on_ac': '打开空调',
      'turn_off_ac': '关闭空调',
      'lock_door': '锁门',
      'unlock_door': '开门',
      'close_curtain': '关闭窗帘',
      'open_curtain': '打开窗帘',
      'turn_on_socket': '打开插座',
      'turn_off_socket': '关闭插座'
    }
    return actionMap[actionId] || '未知动作'
  }

  // 获取动作图标
  static getActionIcon(actionId: string): string {
    const iconMap: Record<string, string> = {
      'turn_on_light': '💡',
      'turn_off_light': '💡',
      'turn_on_ac': '❄️',
      'turn_off_ac': '❄️',
      'lock_door': '🔒',
      'unlock_door': '🔓',
      'close_curtain': '🪟',
      'open_curtain': '🪟',
      'turn_on_socket': '🔌',
      'turn_off_socket': '🔌'
    }
    return iconMap[actionId] || '⚙️'
  }
}