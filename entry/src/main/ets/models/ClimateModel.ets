/**
 * 中央空调/温控 - 领域模型
 *
 * 涵盖：
 *   - ClimateMode  : 模式（制冷 / 制热 / 自动 / 节能 / 睡眠 / 送风）
 *   - FanSpeed     : 风速（自动 / 低 / 中 / 高）
 *   - ThermostatState : 温控实时状态（含 IAS 协议字段：电源、模式、设定温、当前温、目标温、风速、湿度）
 *   - ClimateLogEntry : 操作日志
 *   - ClimateEventPayload : 发到 GatewayEventBus 的 payload
 */

// ==================== 模式 / 风速 ====================
export type ClimateMode = 'cool' | 'heat' | 'auto' | 'eco' | 'sleep' | 'fan'

export type FanSpeed = 'auto' | 'low' | 'mid' | 'high'

// ==================== 温控实时状态 ====================
/**
 * 单台空调（或中央空调一个内机）的实时状态。
 * 字段命名参照 IAinterface（In-App Interface）+ Gree/Midea/Haier Adapter 协议做归一。
 */
export interface ThermostatState {
  id: string                  // 'climate_living'
  name: string                // '客厅中央空调'
  room: string                // '客厅'
  adapter: 'gree' | 'midea' | 'haier' // 当前已激活的适配器
  power: boolean              // 电源开关
  mode: ClimateMode
  fanSpeed: FanSpeed
  /** 设定温度（摄氏度，16-30） */
  targetTemp: number
  /** 当前室内温度（摄氏度，由传感器提供） */
  currentTemp: number
  /** 当前湿度 0-100 */
  humidity: number
  updatedAt: number
}

// ==================== 日志 ====================
export interface ClimateLogEntry {
  id: string
  deviceId: string
  action: 'power' | 'mode' | 'fanSpeed' | 'targetTemp'
  before: string
  after: string
  operator: string            // '家庭成员' / '远程用户' / 'rule'
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
  source: string              // 'manual' | 'rule'
}
