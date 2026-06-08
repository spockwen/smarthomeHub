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
}
