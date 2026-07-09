/**
 * ClimateService
 * ------------------------------------------------------------
 * 中央空调/温控业务服务：负责温控状态管理、操作日志、跨域事件发布。
 *
 * 职责：
 *   1. 维护 ThermostatState（AppStorage 持久化，key = climate_state）
 *   2. 记录温控操作日志（AppStorage 持久化，key = climateLogs）
 *   3. 模式/温度/风速/电源变更时通过 GatewayBus 发布跨域事件
 *
 * 设计原则：
 *   - Service 静态方法 + AppStorage 持久化
 *   - ID 三段式：source·type·seq
 *   - 日志最新在前，最多 5 条
 */

import {
  ThermostatState,
  ClimateMode,
  FanSpeed,
  ClimateLogEntry
} from '../models/ClimateModel'
import { GatewayEvent, EventPayload } from '../models/GatewayModel'
import { GatewayBus } from './GatewayBus'

// ==================== 常量 ====================
const KEY_STATE: string = 'climate_state'
const KEY_LOGS: string = 'climateLogs'
const MAX_LOGS: number = 5

const DEVICE_ID: string = 'climate_living'
const DEVICE_NAME: string = '客厅中央空调'
const ROOM: string = '客厅'
const DEFAULT_ADAPTER: 'gree' | 'midea' | 'haier' = 'gree'

export class ClimateService {

  // ----------------- 状态读写 -----------------

  static getState(): ThermostatState {
    const stored = AppStorage.get<ThermostatState>(KEY_STATE)
    if (stored) return stored
    const init: ThermostatState = {
      id: DEVICE_ID,
      name: DEVICE_NAME,
      room: ROOM,
      adapter: DEFAULT_ADAPTER,
      power: false,
      mode: 'auto' as ClimateMode,
      fanSpeed: 'auto' as FanSpeed,
      targetTemp: 24,
      currentTemp: 26,
      humidity: 50,
      updatedAt: Date.now()
    }
    AppStorage.setOrCreate(KEY_STATE, init)
    return init
  }

  static setState(s: ThermostatState): void {
    AppStorage.setOrCreate(KEY_STATE, s)
  }

  private static patch(partial: Partial<ThermostatState>): ThermostatState {
    const prev = ClimateService.getState()
    const next: ThermostatState = {
      id: prev.id,
      name: prev.name,
      room: prev.room,
      adapter: prev.adapter,
      power: partial.power !== undefined ? partial.power : prev.power,
      mode: partial.mode !== undefined ? partial.mode : prev.mode,
      fanSpeed: partial.fanSpeed !== undefined ? partial.fanSpeed : prev.fanSpeed,
      targetTemp: partial.targetTemp !== undefined ? partial.targetTemp : prev.targetTemp,
      currentTemp: partial.currentTemp !== undefined ? partial.currentTemp : prev.currentTemp,
      humidity: partial.humidity !== undefined ? partial.humidity : prev.humidity,
      updatedAt: Date.now()
    }
    ClimateService.setState(next)
    return next
  }

  // ----------------- 业务动作 -----------------

  static setPower(on: boolean, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    if (prev.power === on) return prev
    const next = ClimateService.patch({ power: on })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'power'),
      deviceId: DEVICE_ID,
      action: 'power',
      before: String(prev.power),
      after: String(on),
      operator: operator,
      timestamp: Date.now()
    })

    const payload = new EventPayload()
    payload.deviceId = DEVICE_ID
    payload.power = next.power
    payload.mode = next.mode
    payload.fanSpeed = next.fanSpeed
    payload.targetTemp = next.targetTemp
    payload.currentTemp = next.currentTemp
    payload.source = 'manual'
    const evt: GatewayEvent = {
      source: 'climate',
      type: 'power_changed',
      timestamp: Date.now(),
      payload: payload
    }
    GatewayBus.publish(evt)

    return next
  }

  static setMode(mode: ClimateMode, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    if (prev.mode === mode) return prev
    const next = ClimateService.patch({ mode: mode })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'mode'),
      deviceId: DEVICE_ID,
      action: 'mode',
      before: String(prev.mode),
      after: String(mode),
      operator: operator,
      timestamp: Date.now()
    })

    const payload = new EventPayload()
    payload.deviceId = DEVICE_ID
    payload.power = next.power
    payload.mode = next.mode
    payload.fanSpeed = next.fanSpeed
    payload.targetTemp = next.targetTemp
    payload.currentTemp = next.currentTemp
    payload.source = 'manual'
    const evt: GatewayEvent = {
      source: 'climate',
      type: 'mode_changed',
      timestamp: Date.now(),
      payload: payload
    }
    GatewayBus.publish(evt)

    return next
  }

  static setTargetTemp(temp: number, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    if (prev.targetTemp === temp) return prev
    const next = ClimateService.patch({ targetTemp: temp })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'targetTemp'),
      deviceId: DEVICE_ID,
      action: 'targetTemp',
      before: String(prev.targetTemp),
      after: String(temp),
      operator: operator,
      timestamp: Date.now()
    })

    const payload = new EventPayload()
    payload.deviceId = DEVICE_ID
    payload.power = next.power
    payload.mode = next.mode
    payload.fanSpeed = next.fanSpeed
    payload.targetTemp = next.targetTemp
    payload.currentTemp = next.currentTemp
    payload.source = 'manual'
    const evt: GatewayEvent = {
      source: 'climate',
      type: 'temperature_changed',
      timestamp: Date.now(),
      payload: payload
    }
    GatewayBus.publish(evt)

    return next
  }

  static setFanSpeed(speed: FanSpeed, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    if (prev.fanSpeed === speed) return prev
    const next = ClimateService.patch({ fanSpeed: speed })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'fanSpeed'),
      deviceId: DEVICE_ID,
      action: 'fanSpeed',
      before: String(prev.fanSpeed),
      after: String(speed),
      operator: operator,
      timestamp: Date.now()
    })

    const payload = new EventPayload()
    payload.deviceId = DEVICE_ID
    payload.power = next.power
    payload.mode = next.mode
    payload.fanSpeed = next.fanSpeed
    payload.targetTemp = next.targetTemp
    payload.currentTemp = next.currentTemp
    payload.source = 'manual'
    const evt: GatewayEvent = {
      source: 'climate',
      type: 'mode_changed',
      timestamp: Date.now(),
      payload: payload
    }
    GatewayBus.publish(evt)

    return next
  }

  // ----------------- 日志读写 -----------------

  static getLogs(): ClimateLogEntry[] {
    const stored = AppStorage.get<ClimateLogEntry[]>(KEY_LOGS)
    if (stored && Array.isArray(stored)) return stored
    return []
  }

  static appendLog(entry: ClimateLogEntry): ClimateLogEntry[] {
    const logs = ClimateService.getLogs()
    logs.unshift(entry)  // 最新在前
    if (logs.length > MAX_LOGS) logs.length = MAX_LOGS
    AppStorage.setOrCreate(KEY_LOGS, logs)
    return logs
  }

  static clearLogs(): void {
    AppStorage.setOrCreate(KEY_LOGS, [])
  }

  // ----------------- 工具 -----------------

  private static genId(...parts: string[]): string {
    return parts.join('·') + '·' + Date.now()
  }
}