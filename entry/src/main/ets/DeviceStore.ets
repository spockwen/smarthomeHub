/**
 * 设备状态管理 - 使用 AppStorage 实现全局响应式状态
 * 所有页面通过 @StorageLink 自动同步状态变化
 */
export class DeviceStore {
  // 初始化全局状态到 AppStorage
  static initialize(): void {
    // 设备状态
    AppStorage.setOrCreate('lightOn', true)
    AppStorage.setOrCreate('bedroomLightOn', false)
    AppStorage.setOrCreate('kitchenLightOn', true)
    AppStorage.setOrCreate('airOn', false)
    AppStorage.setOrCreate('heaterOn', false)
    AppStorage.setOrCreate('doorLocked', true)
    AppStorage.setOrCreate('curtainOpen', false)
    AppStorage.setOrCreate('cameraOn', true)
    AppStorage.setOrCreate('socketOn', true)
    AppStorage.setOrCreate('tvOn', false)
    
    // 环境数据
    AppStorage.setOrCreate('temperature', 26)
    AppStorage.setOrCreate('humidity', 72)
    AppStorage.setOrCreate('onlineDevices', 12)
    AppStorage.setOrCreate('powerUsage', 8.5)
    
    // 场景激活状态
    AppStorage.setOrCreate('activeScene', '')

    // 首页展示的设备ID列表
    AppStorage.setOrCreate('homeDeviceIds', 'light1,air,door,curtain')
  }

  // 首页设备管理
  static getHomeDeviceIds(): string[] {
    const raw = AppStorage.get<string>('homeDeviceIds') || ''
    return raw.split(',').filter((id: string) => id.length > 0)
  }

  static setHomeDeviceIds(ids: string[]): void {
    AppStorage.set('homeDeviceIds', ids.join(','))
  }

  static addHomeDevice(deviceId: string): void {
    const ids = DeviceStore.getHomeDeviceIds()
    if (!ids.includes(deviceId)) {
      ids.push(deviceId)
      DeviceStore.setHomeDeviceIds(ids)
    }
  }

  static removeHomeDevice(deviceId: string): void {
    const ids = DeviceStore.getHomeDeviceIds().filter((id: string) => id !== deviceId)
    DeviceStore.setHomeDeviceIds(ids)
  }

  // 设备控制方法
  static setLightOn(value: boolean): void {
    AppStorage.set('lightOn', value)
  }

  static setBedroomLightOn(value: boolean): void {
    AppStorage.set('bedroomLightOn', value)
  }

  static setKitchenLightOn(value: boolean): void {
    AppStorage.set('kitchenLightOn', value)
  }

  static setAirOn(value: boolean): void {
    AppStorage.set('airOn', value)
  }

  static setHeaterOn(value: boolean): void {
    AppStorage.set('heaterOn', value)
  }

  static setDoorLocked(value: boolean): void {
    AppStorage.set('doorLocked', value)
  }

  static setCurtainOpen(value: boolean): void {
    AppStorage.set('curtainOpen', value)
  }

  static setCameraOn(value: boolean): void {
    AppStorage.set('cameraOn', value)
  }

  static setSocketOn(value: boolean): void {
    AppStorage.set('socketOn', value)
  }

  static setTvOn(value: boolean): void {
    AppStorage.set('tvOn', value)
  }

  static setTemperature(value: number): void {
    AppStorage.set('temperature', value)
  }

  static setHumidity(value: number): void {
    AppStorage.set('humidity', value)
  }
  
  static setActiveScene(sceneId: string): void {
    AppStorage.set('activeScene', sceneId)
  }
}
