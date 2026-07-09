/**
 * 智能网关 - 跨域事件与规则模型
 *
 * 设计目标：
 *   - 定义"事件总线"统一事件格式 GatewayEvent
 *   - 定义跨域规则 CrossDomainRule：触发源 + 条件 + 动作
 *   - 让 service 层只 publish，业务编排由 GatewayService + RuleEngine 完成
 */

import { ClimateMode } from './ClimateModel'

// ==================== 事件源 ====================
/** 事件来源域 */
export type EventSource = 'lock' | 'light' | 'climate' | 'time' | 'sensor'

/** 各域具体事件类型 */
export type LockEventType = 'locked' | 'unlocked' | 'unlock_failed'
export type LightEventType = 'all_off' | 'group_on' | 'group_off'
export type ClimateEventType = 'mode_changed' | 'temperature_changed' | 'power_changed'
export type TimeEventType = 'tick'
export type SensorEventType = 'motion_detected' | 'motion_cleared'

// ==================== 事件总线 ====================
/**
 * GatewayEvent：所有 service 往事件总线上 publish 的统一结构。
 *  - source   : 事件来源域
 *  - type     : 事件子类型（强类型字符串）
 *  - payload  : 与事件相关的上下文（如 deviceId / 新模式名 / 当前时间）
 *  - timestamp: 事件产生时间（ms）
 */
export class EventPayload {
  deviceId: string = ''
  power: boolean = false
  mode: ClimateMode = 'auto'
  fanSpeed: string = 'auto'
  targetTemp: number = 0
  currentTemp: number = 0
  source: string = ''
  doorlockId: string = ''
  state: string = ''
  battery: number = 0
  operator: string = ''
  result: string = ''
}

export interface GatewayEvent {
  source: EventSource
  type: LockEventType | LightEventType | ClimateEventType | TimeEventType | SensorEventType
  payload?: EventPayload
  timestamp: number
}

// ==================== 跨域动作 ====================
/**
 * 跨域动作的目标域 + 操作
 *  - domain: 'light' | 'lock' | 'climate'
 *  - op    : 各域内支持的操作（见下）
 */
export type CrossDomainDomain = 'light' | 'lock' | 'climate'

export type LightOp = 'turn_on_group' | 'turn_off_group' | 'turn_on' | 'turn_off'
export type LockOp = 'lock' | 'unlock'
export type ClimateOp = 'set_mode' | 'set_target_temp' | 'set_power'

export class CrossDomainActionParams {
  on?: boolean = undefined
  mode?: ClimateMode = undefined
  temp?: number = undefined
}

export interface CrossDomainAction {
  domain: CrossDomainDomain
  op: LightOp | LockOp | ClimateOp
  /**
   * 目标标识：
   *   - light   : 灯组 ID / 灯 ID 列表（取决于 op）
   *   - lock    : 门锁 ID（单值字符串）
   *   - climate : 空调 ID（单值字符串）
   */
  targets: string[]
  /** 额外参数：brightness / temperature / mode 等 */
  params?: CrossDomainActionParams
}

// ==================== 跨域规则 ====================
/**
 * 跨域规则触发条件。
 *  - source + type 唯一确定一条事件
 *  - window 可选：仅在指定时间段内生效
 */
export interface CrossDomainTrigger {
  source: EventSource
  type: LockEventType | LightEventType | ClimateEventType | TimeEventType | SensorEventType
  /** 时间窗口 HH:mm-HH:mm，支持跨夜。可选 */
  window?: string
}

/** 规则启用开关 */
export interface CrossDomainRule {
  id: string
  name: string
  enabled: boolean
  trigger: CrossDomainTrigger
  actions: CrossDomainAction[]
  /** 累计触发次数 */
  fireCount: number
  lastFiredTime: number
}

// ==================== 订阅者 ====================
/**
 * 订阅者回调签名。GatewayService 内部维护静态订阅者列表。
 *  - 使用字符串 ID 去重（避免重复订阅）。
 */
export type GatewayEventHandler = (event: GatewayEvent) => void

export interface GatewaySubscriber {
  id: string
  sourceFilter?: EventSource // 不填表示订阅所有源
  handler: GatewayEventHandler
}

// ==================== 派发结果 ====================
/**
 * 一次 publish 触发的派发结果：哪些规则被激活、产生哪些动作。
 * 供日志 / UI 展示使用。
 */
export interface DispatchResult {
  event: GatewayEvent
  firedRuleIds: string[]
  actions: CrossDomainAction[]
}
