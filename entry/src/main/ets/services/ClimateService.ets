/**
 * ClimateService
 * ------------------------------------------------------------
 * 中央空调/温控业务服务：负责温控状态管理、操作日志、跨域事件发布。
 *
 * 架构：
 *   - IAirConditioner + 品牌适配器（Gree/Midea/Haier）
 *   - ACStateMachine 状态机（模式/温度/风速约束与状态流转）
 *   - ClimateService 业务层（调用状态机 + 记录日志 + 发布事件）
 *
 * 职责：
 *   1. 维护 ThermostatState（AppStorage 持久化，key = climate_state）
 *   2. 通过 ACStateMachine 校验所有状态变更
 *   3. 通过 IAirConditioner 适配器编码/解码品牌协议
 *   4. 记录温控操作日志（AppStorage 持久化，key = climateLogs）
 *   5. 模式/温度/风速/电源变更时通过 GatewayBus 发布跨域事件
 */

import {
  ThermostatState,
  ClimateMode,
  FanSpeed,
  ClimateLogEntry,
  AdapterBrand,
  ACStateMachine,
  ACStateMachineState,
  ACStateMachineTransitionResult,
  ACAdapterFactory,
  ACCommandParams,
  IAirConditioner
} from '../models/ClimateModel'
import {
  GatewayEvent,
  EventPayload,
  ClimateEventType
} from '../models/GatewayModel'
import { GatewayBus } from './GatewayBus'

const KEY_STATE: string = 'climate_state'
const KEY_LOGS: string = 'climateLogs'
const MAX_LOGS: number = 5

const DEVICE_ID: string = 'climate_living'
const DEVICE_NAME: string = '客厅中央空调'
const ROOM: string = '客厅'
const DEFAULT_ADAPTER: AdapterBrand = 'gree'

export class ClimateService {
  private static stateMachine: ACStateMachine = new ACStateMachine(ACAdapterFactory.getAdapter(DEFAULT_ADAPTER))

  static getStateMachine(): ACStateMachine {
    return ClimateService.stateMachine
  }

  static getCurrentAdapter(): IAirConditioner {
    return ClimateService.stateMachine.getAdapter()
  }

  // ----------------- 状态读写 -----------------

  static getState(): ThermostatState {
    const stored = AppStorage.get<ThermostatState>(KEY_STATE)
    if (stored) {
      ClimateService.stateMachine = new ACStateMachine(ACAdapterFactory.getAdapter(stored.adapter))
      return stored
    }
    const adapter: IAirConditioner = ACAdapterFactory.getAdapter(DEFAULT_ADAPTER)
    const init: ThermostatState = {
      id: DEVICE_ID,
      name: DEVICE_NAME,
      room: ROOM,
      adapter: DEFAULT_ADAPTER,
      power: false,
      mode: adapter.getPowerOnDefaultMode(),
      fanSpeed: adapter.getPowerOnDefaultFan(),
      targetTemp: adapter.getPowerOnDefaultTemp(),
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
      adapter: partial.adapter !== undefined ? partial.adapter : prev.adapter,
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

  // ----------------- 适配器切换 -----------------

  static switchAdapter(brand: AdapterBrand, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    if (prev.adapter === brand) return prev

    const newAdapter: IAirConditioner = ACAdapterFactory.getAdapter(brand)
    const currentSmState: ACStateMachineState = {
      power: prev.power,
      mode: prev.mode,
      fanSpeed: prev.fanSpeed,
      targetTemp: prev.targetTemp
    }
    const adjustedState = ClimateService.stateMachine.switchAdapter(newAdapter, currentSmState)

    const next: ThermostatState = {
      id: prev.id,
      name: prev.name,
      room: prev.room,
      adapter: brand,
      power: adjustedState.power,
      mode: adjustedState.mode,
      fanSpeed: adjustedState.fanSpeed,
      targetTemp: adjustedState.targetTemp,
      currentTemp: prev.currentTemp,
      humidity: prev.humidity,
      updatedAt: Date.now()
    }
    ClimateService.setState(next)

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'adapter'),
      deviceId: DEVICE_ID,
      action: 'adapter',
      before: prev.adapter,
      after: brand,
      operator: operator,
      timestamp: Date.now()
    })

    const cmdParams: ACCommandParams = { mode: adjustedState.mode, targetTemp: adjustedState.targetTemp, fanSpeed: adjustedState.fanSpeed }
    const cmd: string = newAdapter.encodeCommand('set_mode', cmdParams)
    console.info('[ClimateService] adapter switch command:', cmd)

    ClimateService.publishEvent(next, 'manual')
    return next
  }

  // ----------------- 业务动作（通过状态机） -----------------

  static setPower(on: boolean, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    const currentSmState: ACStateMachineState = { power: prev.power, mode: prev.mode, fanSpeed: prev.fanSpeed, targetTemp: prev.targetTemp }
    const result: ACStateMachineTransitionResult = ClimateService.stateMachine.transitionPower(currentSmState, on)

    if (!result.success) {
      console.info('[ClimateService] setPower rejected:', result.reason)
      return prev
    }

    const adapter: IAirConditioner = ClimateService.stateMachine.getAdapter()
    const cmd: string = adapter.encodeCommand('set_power', { power: on })
    console.info('[ClimateService] command:', cmd)

    const next = ClimateService.patch({
      power: result.state.power,
      mode: result.state.mode,
      fanSpeed: result.state.fanSpeed,
      targetTemp: result.state.targetTemp
    })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'power'),
      deviceId: DEVICE_ID,
      action: 'power',
      before: String(prev.power),
      after: String(on),
      operator: operator,
      timestamp: Date.now()
    })

    ClimateService.publishEvent(next, operator === 'gateway' ? 'rule' : 'manual')
    return next
  }

  static setMode(mode: ClimateMode, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    const currentSmState: ACStateMachineState = { power: prev.power, mode: prev.mode, fanSpeed: prev.fanSpeed, targetTemp: prev.targetTemp }
    const result: ACStateMachineTransitionResult = ClimateService.stateMachine.transitionMode(currentSmState, mode)

    if (!result.success) {
      console.info('[ClimateService] setMode rejected:', result.reason)
      return prev
    }

    const adapter: IAirConditioner = ClimateService.stateMachine.getAdapter()
    const cmd: string = adapter.encodeCommand('set_mode', { mode: mode })
    console.info('[ClimateService] command:', cmd)

    const next = ClimateService.patch({
      mode: result.state.mode,
      fanSpeed: result.state.fanSpeed,
      targetTemp: result.state.targetTemp
    })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'mode'),
      deviceId: DEVICE_ID,
      action: 'mode',
      before: String(prev.mode),
      after: String(mode),
      operator: operator,
      timestamp: Date.now()
    })

    const extraReason: string = result.reason
    if (extraReason) {
      ClimateService.appendLog({
        id: ClimateService.genId('climate', 'auto_adjust'),
        deviceId: DEVICE_ID,
        action: 'targetTemp',
        before: String(prev.targetTemp),
        after: String(result.state.targetTemp),
        operator: 'state_machine',
        timestamp: Date.now()
      })
    }

    ClimateService.publishEvent(next, operator === 'gateway' ? 'rule' : 'manual')
    return next
  }

  static setTargetTemp(temp: number, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    const currentSmState: ACStateMachineState = { power: prev.power, mode: prev.mode, fanSpeed: prev.fanSpeed, targetTemp: prev.targetTemp }
    const result: ACStateMachineTransitionResult = ClimateService.stateMachine.transitionTemp(currentSmState, temp)

    if (!result.success) {
      console.info('[ClimateService] setTargetTemp rejected:', result.reason)
      return prev
    }

    const adapter: IAirConditioner = ClimateService.stateMachine.getAdapter()
    const cmd: string = adapter.encodeCommand('set_temp', { targetTemp: result.state.targetTemp })
    console.info('[ClimateService] command:', cmd)

    const next = ClimateService.patch({
      targetTemp: result.state.targetTemp
    })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'targetTemp'),
      deviceId: DEVICE_ID,
      action: 'targetTemp',
      before: String(prev.targetTemp),
      after: String(result.state.targetTemp),
      operator: operator,
      timestamp: Date.now()
    })

    ClimateService.publishEvent(next, operator === 'gateway' ? 'rule' : 'manual')
    return next
  }

  static setFanSpeed(speed: FanSpeed, operator: string = '家庭成员'): ThermostatState {
    const prev = ClimateService.getState()
    const currentSmState: ACStateMachineState = { power: prev.power, mode: prev.mode, fanSpeed: prev.fanSpeed, targetTemp: prev.targetTemp }
    const result: ACStateMachineTransitionResult = ClimateService.stateMachine.transitionFan(currentSmState, speed)

    if (!result.success) {
      console.info('[ClimateService] setFanSpeed rejected:', result.reason)
      return prev
    }

    const adapter: IAirConditioner = ClimateService.stateMachine.getAdapter()
    const cmd: string = adapter.encodeCommand('set_fan', { fanSpeed: speed })
    console.info('[ClimateService] command:', cmd)

    const next = ClimateService.patch({
      fanSpeed: result.state.fanSpeed
    })

    ClimateService.appendLog({
      id: ClimateService.genId('climate', 'fanSpeed'),
      deviceId: DEVICE_ID,
      action: 'fanSpeed',
      before: String(prev.fanSpeed),
      after: String(speed),
      operator: operator,
      timestamp: Date.now()
    })

    ClimateService.publishEvent(next, operator === 'gateway' ? 'rule' : 'manual')
    return next
  }

  // ----------------- 事件发布 -----------------

  private static publishEvent(state: ThermostatState, source: string): void {
    const payload = new EventPayload()
    payload.deviceId = DEVICE_ID
    payload.power = state.power
    payload.mode = state.mode
    payload.fanSpeed = state.fanSpeed
    payload.targetTemp = state.targetTemp
    payload.currentTemp = state.currentTemp
    payload.source = source

    let eventType: ClimateEventType = 'mode_changed'
    if (!state.power) {
      eventType = 'power_changed'
    }

    const evt: GatewayEvent = {
      source: 'climate',
      type: eventType,
      timestamp: Date.now(),
      payload: payload
    }
    GatewayBus.publish(evt)
  }

  // ----------------- 日志读写 -----------------

  static getLogs(): ClimateLogEntry[] {
    const stored = AppStorage.get<ClimateLogEntry[]>(KEY_LOGS)
    if (stored && Array.isArray(stored)) return stored
    return []
  }

  static appendLog(entry: ClimateLogEntry): ClimateLogEntry[] {
    const logs = ClimateService.getLogs()
    logs.unshift(entry)
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
