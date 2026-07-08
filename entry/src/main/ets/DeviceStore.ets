/**
 * 设备状态管理 - 使用 AppStorage 实现全局响应式状态
 * 所有页面通过 @StorageLink 自动同步状态变化
 */
import { ConfigurationConstant } from '@kit.AbilityKit'

export class DeviceStore {
  static initialize(): void {
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
    AppStorage.setOrCreate('airPurifierOn', false)
    AppStorage.setOrCreate('robotVacuumOn', false)
    AppStorage.setOrCreate('waterHeaterOn', false)
    AppStorage.setOrCreate('doorSensorOn', true)
    AppStorage.setOrCreate('bedsideLampOn', false)
    AppStorage.setOrCreate('temperature', 26)
    AppStorage.setOrCreate('humidity', 72)
    AppStorage.setOrCreate('onlineDevices', 12)
    AppStorage.setOrCreate('powerUsage', 8.5)
    AppStorage.setOrCreate('activeScene', '')
    AppStorage.setOrCreate('homeDeviceIds', 'light1,air,door,curtain')
    AppStorage.setOrCreate('themeMode', 'follow-system')
    AppStorage.setOrCreate('isDarkMode', false)
    AppStorage.setOrCreate('systemColorMode', ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
  }

  static setThemeMode(mode: string): void {
    AppStorage.set('themeMode', mode)
    DeviceStore.applyThemeMode(mode)
  }

  static applyThemeMode(mode: string): void {
    const systemMode = AppStorage.get<number>('systemColorMode') ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
    let isDark = false
    if (mode === 'dark') {
      isDark = true
    } else if (mode === 'follow-system') {
      isDark = systemMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
    }
    AppStorage.set('isDarkMode', isDark)
  }

  static onSystemColorModeChange(systemMode: number): void {
    AppStorage.set('systemColorMode', systemMode)
    const currentMode = AppStorage.get<string>('themeMode') || 'follow-system'
    if (currentMode === 'follow-system') {
      const isDark = systemMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      AppStorage.set('isDarkMode', isDark)
    }
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

  static setAirPurifierOn(value: boolean): void {
    AppStorage.set('airPurifierOn', value)
  }

  static setRobotVacuumOn(value: boolean): void {
    AppStorage.set('robotVacuumOn', value)
  }

  static setWaterHeaterOn(value: boolean): void {
    AppStorage.set('waterHeaterOn', value)
  }

  static setDoorSensorOn(value: boolean): void {
    AppStorage.set('doorSensorOn', value)
  }

  static setBedsideLampOn(value: boolean): void {
    AppStorage.set('bedsideLampOn', value)
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

  static triggerScene(sceneId: string): void {
    const wasActive = AppStorage.get<string>('activeScene') === sceneId
    const newActiveScene = wasActive ? '' : sceneId
    DeviceStore.setActiveScene(newActiveScene)
    DeviceStore.applySceneDevices(sceneId, !wasActive)
  }

  static applySceneDevices(sceneId: string, activating: boolean): void {
    const on = activating
    const off = !activating
    if (sceneId === 'home') {
      DeviceStore.setLightOn(on)
      DeviceStore.setAirOn(on)
      DeviceStore.setCurtainOpen(off)
    } else if (sceneId === 'leave' || sceneId === 'leave_home') {
      DeviceStore.setLightOn(off)
      DeviceStore.setBedroomLightOn(off)
      DeviceStore.setKitchenLightOn(off)
      DeviceStore.setAirOn(off)
      DeviceStore.setHeaterOn(off)
      DeviceStore.setDoorLocked(on)
      DeviceStore.setCameraOn(on)
      DeviceStore.setCurtainOpen(off)
      DeviceStore.setSocketOn(off)
      DeviceStore.setTvOn(off)
      DeviceStore.setBedsideLampOn(off)
      DeviceStore.setAirPurifierOn(on)
      DeviceStore.setWaterHeaterOn(off)
      DeviceStore.setRobotVacuumOn(off)
    } else if (sceneId === 'sleep' || sceneId === 'sleep_scene') {
      DeviceStore.setLightOn(off)
      DeviceStore.setBedroomLightOn(off)
      DeviceStore.setKitchenLightOn(off)
      DeviceStore.setAirOn(on)
      DeviceStore.setCurtainOpen(off)
      DeviceStore.setTvOn(off)
      DeviceStore.setBedsideLampOn(off)
      DeviceStore.setSocketOn(off)
      DeviceStore.setAirPurifierOn(on)
    } else if (sceneId === 'movie') {
      DeviceStore.setLightOn(off)
      DeviceStore.setBedroomLightOn(off)
      DeviceStore.setKitchenLightOn(off)
      DeviceStore.setCurtainOpen(off)
      DeviceStore.setTvOn(on)
    } else if (sceneId === 'alert') {
      DeviceStore.setCameraOn(on)
      DeviceStore.setDoorSensorOn(on)
    } else if (sceneId === 'morning') {
      DeviceStore.setLightOn(on)
      DeviceStore.setBedroomLightOn(on)
      DeviceStore.setBedsideLampOn(off)
      DeviceStore.setAirOn(off)
      DeviceStore.setCurtainOpen(on)
      DeviceStore.setAirPurifierOn(on)
    } else if (sceneId === 'back_home') {
      DeviceStore.setLightOn(on)
      DeviceStore.setBedroomLightOn(on)
      DeviceStore.setAirOn(on)
      DeviceStore.setCurtainOpen(off)
      DeviceStore.setAirPurifierOn(off)
      DeviceStore.setRobotVacuumOn(off)
      DeviceStore.setWaterHeaterOn(on)
    }
  }

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
}
