/**
 * 中央空调/温控 - 领域模型
 *
 * 涵盖：
 *   - IAirConditioner  : 空调通用接口（适配器模式抽象层）
 *   - GreeAdapter      : 格力空调适配器
 *   - MideaAdapter     : 美的空调适配器
 *   - HaierAdapter     : 海尔空调适配器
 *   - ACStateMachine   : 空调状态机（模式/温度/风速约束与状态流转）
 *   - ClimateMode      : 模式（制冷 / 制热 / 自动 / 节能 / 睡眠 / 送风）
 *   - FanSpeed         : 风速（自动 / 低 / 中 / 高）
 *   - ThermostatState  : 温控实时状态
 *   - ClimateLogEntry  : 操作日志
 *   - ClimateEventPayload : 发到 GatewayEventBus 的 payload
 */

// ==================== 模式 / 风速 ====================
export type ClimateMode = 'cool' | 'heat' | 'auto' | 'eco' | 'sleep' | 'fan'

export type FanSpeed = 'auto' | 'low' | 'mid' | 'high'

export type AdapterBrand = 'gree' | 'midea' | 'haier'

// ==================== 空调通用接口 (IAirConditioner) ====================
/**
 * IAirConditioner — 适配器模式抽象接口
 * 所有品牌适配器必须实现此接口，屏蔽底层协议差异。
 * 上层业务只依赖此接口，不直接与品牌协议交互。
 */
export interface IAirConditioner {
  readonly brand: AdapterBrand
  readonly brandName: string
  readonly supportedModes: ClimateMode[]
  readonly supportedFanSpeeds: FanSpeed[]

  getTempMin(mode: ClimateMode): number
  getTempMax(mode: ClimateMode): number

  encodeCommand(action: string, params: ACCommandParams): string
  decodeResponse(raw: string): ACResponseData

  validateTransition(from: ACStateMachineState, to: ACStateMachineState): boolean
  getPowerOnDefaultMode(): ClimateMode
  getPowerOnDefaultTemp(): number
  getPowerOnDefaultFan(): FanSpeed
}

export interface ACCommandParams {
  power?: boolean
  mode?: ClimateMode
  targetTemp?: number
  fanSpeed?: FanSpeed
}

export interface ACResponseData {
  success: boolean
  errorCode: number
  errorMessage: string
}

export interface ACStateMachineState {
  power: boolean
  mode: ClimateMode
  fanSpeed: FanSpeed
  targetTemp: number
}

// ==================== 格力适配器 ====================
export class GreeAdapter implements IAirConditioner {
  readonly brand: AdapterBrand = 'gree'
  readonly brandName: string = '格力'
  readonly supportedModes: ClimateMode[] = ['cool', 'heat', 'auto', 'eco', 'sleep', 'fan']
  readonly supportedFanSpeeds: FanSpeed[] = ['auto', 'low', 'mid', 'high']

  getTempMin(mode: ClimateMode): number {
    if (mode === 'heat') return 16
    if (mode === 'cool') return 16
    if (mode === 'auto') return 16
    if (mode === 'eco') return 26
    if (mode === 'sleep') return 16
    return 16
  }

  getTempMax(mode: ClimateMode): number {
    if (mode === 'heat') return 30
    if (mode === 'cool') return 30
    if (mode === 'auto') return 30
    if (mode === 'eco') return 26
    if (mode === 'sleep') return 26
    return 30
  }

  encodeCommand(action: string, params: ACCommandParams): string {
    const brandCode: string = 'Gree'
    if (action === 'set_power') {
      return brandCode + ':CMD_POWER:' + (params.power ? 'ON' : 'OFF')
    }
    if (action === 'set_mode') {
      return brandCode + ':CMD_MODE:' + (params.mode || 'auto')
    }
    if (action === 'set_temp') {
      return brandCode + ':CMD_TEMP:' + (params.targetTemp?.toString() || '24')
    }
    if (action === 'set_fan') {
      return brandCode + ':CMD_FAN:' + (params.fanSpeed || 'auto')
    }
    return brandCode + ':CMD_UNKNOWN'
  }

  decodeResponse(raw: string): ACResponseData {
    if (raw.startsWith('OK')) {
      return { success: true, errorCode: 0, errorMessage: '' }
    }
    return { success: false, errorCode: 1, errorMessage: raw }
  }

  validateTransition(from: ACStateMachineState, to: ACStateMachineState): boolean {
    if (!to.power) return true
    if (to.targetTemp < this.getTempMin(to.mode)) return false
    if (to.targetTemp > this.getTempMax(to.mode)) return false
    if (!this.supportedModes.includes(to.mode)) return false
    if (!this.supportedFanSpeeds.includes(to.fanSpeed)) return false
    if (to.mode === 'fan') {
      if (to.targetTemp !== from.targetTemp) return false
    }
    return true
  }

  getPowerOnDefaultMode(): ClimateMode {
    return 'auto'
  }

  getPowerOnDefaultTemp(): number {
    return 24
  }

  getPowerOnDefaultFan(): FanSpeed {
    return 'auto'
  }
}

// ==================== 美的适配器 ====================
export class MideaAdapter implements IAirConditioner {
  readonly brand: AdapterBrand = 'midea'
  readonly brandName: string = '美的'
  readonly supportedModes: ClimateMode[] = ['cool', 'heat', 'auto', 'eco', 'sleep', 'fan']
  readonly supportedFanSpeeds: FanSpeed[] = ['auto', 'low', 'mid', 'high']

  getTempMin(mode: ClimateMode): number {
    if (mode === 'heat') return 17
    if (mode === 'cool') return 16
    if (mode === 'auto') return 16
    if (mode === 'eco') return 26
    if (mode === 'sleep') return 17
    return 16
  }

  getTempMax(mode: ClimateMode): number {
    if (mode === 'heat') return 30
    if (mode === 'cool') return 30
    if (mode === 'auto') return 30
    if (mode === 'eco') return 27
    if (mode === 'sleep') return 27
    return 30
  }

  encodeCommand(action: string, params: ACCommandParams): string {
    const brandCode: string = 'Midea'
    if (action === 'set_power') {
      return brandCode + ':PWR:' + (params.power ? '1' : '0')
    }
    if (action === 'set_mode') {
      const modeMap: Record<string, string> = {
        'cool': '0', 'heat': '1', 'auto': '2', 'eco': '3', 'sleep': '4', 'fan': '5'
      }
      return brandCode + ':MOD:' + (modeMap[params.mode || 'auto'] || '2')
    }
    if (action === 'set_temp') {
      return brandCode + ':TMP:' + (params.targetTemp?.toString() || '24')
    }
    if (action === 'set_fan') {
      const fanMap: Record<string, string> = {
        'auto': '0', 'low': '1', 'mid': '2', 'high': '3'
      }
      return brandCode + ':FAN:' + (fanMap[params.fanSpeed || 'auto'] || '0')
    }
    return brandCode + ':UNK'
  }

  decodeResponse(raw: string): ACResponseData {
    if (raw.startsWith('ACK')) {
      return { success: true, errorCode: 0, errorMessage: '' }
    }
    return { success: false, errorCode: 2, errorMessage: raw }
  }

  validateTransition(from: ACStateMachineState, to: ACStateMachineState): boolean {
    if (!to.power) return true
    if (to.targetTemp < this.getTempMin(to.mode)) return false
    if (to.targetTemp > this.getTempMax(to.mode)) return false
    if (!this.supportedModes.includes(to.mode)) return false
    if (!this.supportedFanSpeeds.includes(to.fanSpeed)) return false
    if (to.mode === 'fan') {
      if (to.targetTemp !== from.targetTemp) return false
    }
    return true
  }

  getPowerOnDefaultMode(): ClimateMode {
    return 'cool'
  }

  getPowerOnDefaultTemp(): number {
    return 26
  }

  getPowerOnDefaultFan(): FanSpeed {
    return 'auto'
  }
}

// ==================== 海尔适配器 ====================
export class HaierAdapter implements IAirConditioner {
  readonly brand: AdapterBrand = 'haier'
  readonly brandName: string = '海尔'
  readonly supportedModes: ClimateMode[] = ['cool', 'heat', 'auto', 'eco', 'sleep', 'fan']
  readonly supportedFanSpeeds: FanSpeed[] = ['auto', 'low', 'mid', 'high']

  getTempMin(mode: ClimateMode): number {
    if (mode === 'heat') return 16
    if (mode === 'cool') return 16
    if (mode === 'auto') return 16
    if (mode === 'eco') return 26
    if (mode === 'sleep') return 16
    return 16
  }

  getTempMax(mode: ClimateMode): number {
    if (mode === 'heat') return 30
    if (mode === 'cool') return 30
    if (mode === 'auto') return 30
    if (mode === 'eco') return 26
    if (mode === 'sleep') return 25
    return 30
  }

  encodeCommand(action: string, params: ACCommandParams): string {
    const brandCode: string = 'Haier'
    if (action === 'set_power') {
      return brandCode + ':POWER_' + (params.power ? 'ON' : 'OFF')
    }
    if (action === 'set_mode') {
      return brandCode + ':MODE_' + (params.mode || 'auto').toUpperCase()
    }
    if (action === 'set_temp') {
      return brandCode + ':TEMP_' + (params.targetTemp?.toString() || '24')
    }
    if (action === 'set_fan') {
      return brandCode + ':FAN_' + (params.fanSpeed || 'auto').toUpperCase()
    }
    return brandCode + ':UNKNOWN'
  }

  decodeResponse(raw: string): ACResponseData {
    if (raw.startsWith('RESP:OK')) {
      return { success: true, errorCode: 0, errorMessage: '' }
    }
    return { success: false, errorCode: 3, errorMessage: raw }
  }

  validateTransition(from: ACStateMachineState, to: ACStateMachineState): boolean {
    if (!to.power) return true
    if (to.targetTemp < this.getTempMin(to.mode)) return false
    if (to.targetTemp > this.getTempMax(to.mode)) return false
    if (!this.supportedModes.includes(to.mode)) return false
    if (!this.supportedFanSpeeds.includes(to.fanSpeed)) return false
    if (to.mode === 'fan') {
      if (to.targetTemp !== from.targetTemp) return false
    }
    if (to.mode === 'sleep' && to.targetTemp > 25) return false
    return true
  }

  getPowerOnDefaultMode(): ClimateMode {
    return 'auto'
  }

  getPowerOnDefaultTemp(): number {
    return 25
  }

  getPowerOnDefaultFan(): FanSpeed {
    return 'low'
  }
}

// ==================== 适配器工厂 ====================
export class ACAdapterFactory {
  private static greeInstance: GreeAdapter = new GreeAdapter()
  private static mideaInstance: MideaAdapter = new MideaAdapter()
  private static haierInstance: HaierAdapter = new HaierAdapter()

  static getAdapter(brand: AdapterBrand): IAirConditioner {
    if (brand === 'gree') return ACAdapterFactory.greeInstance
    if (brand === 'midea') return ACAdapterFactory.mideaInstance
    if (brand === 'haier') return ACAdapterFactory.haierInstance
    return ACAdapterFactory.greeInstance
  }

  static getAllAdapters(): IAirConditioner[] {
    return [
      ACAdapterFactory.greeInstance,
      ACAdapterFactory.mideaInstance,
      ACAdapterFactory.haierInstance
    ]
  }
}

// ==================== 空调状态机 ====================
/**
 * ACStateMachine — 管理空调状态流转
 *
 * 规则：
 *   1. 关机状态只能开机，其他操作被拒绝
 *   2. 开机时自动切换到适配器默认模式/温度/风速
 *   3. 切换模式时，若当前温度超出新模式范围，自动校正到最近合法值
 *   4. 切换到送风模式时，温度锁定不变（送风不调温）
 *   5. 切换到节能/睡眠模式时，若风速为high则降为mid
 *   6. 所有状态变更必须通过适配器 validateTransition 校验
 *   7. 制冷模式下，设定温度不能低于16℃（各品牌可能有差异）
 */
export class ACStateMachine {
  private adapter: IAirConditioner

  constructor(adapter: IAirConditioner) {
    this.adapter = adapter
  }

  getAdapter(): IAirConditioner {
    return this.adapter
  }

  switchAdapter(newAdapter: IAirConditioner, currentState: ACStateMachineState): ACStateMachineState {
    this.adapter = newAdapter
    const adjusted: ACStateMachineState = {
      power: currentState.power,
      mode: currentState.mode,
      fanSpeed: currentState.fanSpeed,
      targetTemp: currentState.targetTemp
    }
    if (!newAdapter.supportedModes.includes(adjusted.mode)) {
      adjusted.mode = newAdapter.getPowerOnDefaultMode()
    }
    if (!newAdapter.supportedFanSpeeds.includes(adjusted.fanSpeed)) {
      adjusted.fanSpeed = newAdapter.getPowerOnDefaultFan()
    }
    adjusted.targetTemp = this.clampTemp(adjusted.targetTemp, adjusted.mode)
    return adjusted
  }

  transitionPower(current: ACStateMachineState, powerOn: boolean): ACStateMachineTransitionResult {
    if (powerOn === current.power) {
      return { success: false, state: current, reason: powerOn ? '已开机' : '已关机' }
    }
    if (powerOn) {
      const newState: ACStateMachineState = {
        power: true,
        mode: this.adapter.getPowerOnDefaultMode(),
        fanSpeed: this.adapter.getPowerOnDefaultFan(),
        targetTemp: this.adapter.getPowerOnDefaultTemp()
      }
      if (!this.adapter.validateTransition(current, newState)) {
        return { success: false, state: current, reason: '开机状态校验失败' }
      }
      return { success: true, state: newState, reason: '' }
    } else {
      const newState: ACStateMachineState = {
        power: false,
        mode: current.mode,
        fanSpeed: current.fanSpeed,
        targetTemp: current.targetTemp
      }
      return { success: true, state: newState, reason: '' }
    }
  }

  transitionMode(current: ACStateMachineState, mode: ClimateMode): ACStateMachineTransitionResult {
    if (!current.power) {
      return { success: false, state: current, reason: '空调未开机' }
    }
    if (current.mode === mode) {
      return { success: false, state: current, reason: '已是该模式' }
    }
    if (!this.adapter.supportedModes.includes(mode)) {
      return { success: false, state: current, reason: '该品牌不支持此模式' }
    }
    let newTemp: number = current.targetTemp
    if (mode !== 'fan') {
      newTemp = this.clampTemp(current.targetTemp, mode)
    }
    let newFan: FanSpeed = current.fanSpeed
    if ((mode === 'eco' || mode === 'sleep') && current.fanSpeed === 'high') {
      newFan = 'mid'
    }
    const newState: ACStateMachineState = {
      power: true,
      mode: mode,
      fanSpeed: newFan,
      targetTemp: newTemp
    }
    if (!this.adapter.validateTransition(current, newState)) {
      return { success: false, state: current, reason: '状态校验失败' }
    }
    return { success: true, state: newState, reason: '' }
  }

  transitionTemp(current: ACStateMachineState, targetTemp: number): ACStateMachineTransitionResult {
    if (!current.power) {
      return { success: false, state: current, reason: '空调未开机' }
    }
    if (current.mode === 'fan') {
      return { success: false, state: current, reason: '送风模式不支持调温' }
    }
    const clamped: number = this.clampTemp(targetTemp, current.mode)
    if (clamped === current.targetTemp && targetTemp === current.targetTemp) {
      return { success: false, state: current, reason: '温度未变' }
    }
    const newState: ACStateMachineState = {
      power: true,
      mode: current.mode,
      fanSpeed: current.fanSpeed,
      targetTemp: clamped
    }
    if (!this.adapter.validateTransition(current, newState)) {
      return { success: false, state: current, reason: '温度超出范围' }
    }
    return { success: true, state: newState, reason: clamped !== targetTemp ? '温度已校正至合法范围' : '' }
  }

  transitionFan(current: ACStateMachineState, fanSpeed: FanSpeed): ACStateMachineTransitionResult {
    if (!current.power) {
      return { success: false, state: current, reason: '空调未开机' }
    }
    if (current.fanSpeed === fanSpeed) {
      return { success: false, state: current, reason: '风速未变' }
    }
    if (!this.adapter.supportedFanSpeeds.includes(fanSpeed)) {
      return { success: false, state: current, reason: '该品牌不支持此风速' }
    }
    const newState: ACStateMachineState = {
      power: true,
      mode: current.mode,
      fanSpeed: fanSpeed,
      targetTemp: current.targetTemp
    }
    if (!this.adapter.validateTransition(current, newState)) {
      return { success: false, state: current, reason: '风速校验失败' }
    }
    return { success: true, state: newState, reason: '' }
  }

  clampTemp(temp: number, mode: ClimateMode): number {
    const min: number = this.adapter.getTempMin(mode)
    const max: number = this.adapter.getTempMax(mode)
    if (temp < min) return min
    if (temp > max) return max
    return temp
  }
}

export interface ACStateMachineTransitionResult {
  success: boolean
  state: ACStateMachineState
  reason: string
}

// ==================== 温控实时状态 ====================
export interface ThermostatState {
  id: string
  name: string
  room: string
  adapter: AdapterBrand
  power: boolean
  mode: ClimateMode
  fanSpeed: FanSpeed
  targetTemp: number
  currentTemp: number
  humidity: number
  updatedAt: number
}

// ==================== 日志 ====================
export interface ClimateLogEntry {
  id: string
  deviceId: string
  action: 'power' | 'mode' | 'fanSpeed' | 'targetTemp' | 'adapter'
  before: string
  after: string
  operator: string
  timestamp: number
}

// ==================== 事件 payload ====================
export interface ClimateEventPayload {
  deviceId: string
  power: boolean
  mode: ClimateMode
  fanSpeed: FanSpeed
  targetTemp: number
  currentTemp: number
  source: string
}
