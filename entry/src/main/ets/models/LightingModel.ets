/**
 * 智能照明中心 - 领域模型
 * 涵盖：灯(Light) / 灯组(LightGroup) / 人体感应器(MotionSensor)
 *       / IFTTT 联动规则(IfThisRule) / 触发事件(TriggerEvent)
 */

// ==================== 灯 ====================
export interface Light {
  id: string              // 唯一 ID，例如 'light_living_main'
  name: string            // 展示名，例如 '客厅吊灯'
  room: string            // 所属房间，例如 '客厅'
  groupId: string         // 所属灯组 ID
  isOn: boolean           // 当前开关
  brightness: number      // 亮度 0-100
}

// ==================== 灯组 ====================
export interface LightGroup {
  id: string              // 'group_living'
  name: string            // '客厅灯组'
  room: string            // '客厅'
}

// ==================== 人体感应器 ====================
export interface MotionSensor {
  id: string              // 'sensor_living'
  name: string            // '客厅红外'
  room: string            // '客厅'
  detected: boolean       // 是否当前感应到人
  lastTriggerTime: number // 最近一次触发时间戳(ms)，0 表示从未触发
}

// ==================== 触发事件 ====================
export type RuleTriggerEvent = 'motion_detected' | 'motion_cleared'

export interface TriggerEvent {
  type: RuleTriggerEvent
  sensorId: string
  timestamp: number
}

// ==================== IFTTT 联动规则 ====================
export type RuleActionType = 'turn_on' | 'turn_off' | 'toggle' | 'turn_on_group'

export interface RuleAction {
  type: RuleActionType
  // turn_on / toggle / turn_off 作用于灯 ID 列表
  // turn_on_group 作用于灯组 ID 列表
  targetIds: string[]
  brightness?: number // 仅 turn_on / turn_on_group 时生效
}

export interface RuleCondition {
  // 时间窗口：HH:mm，例如 '18:00'。未设置表示不限。
  timeFrom?: string
  timeTo?: string
  // 简易"夜晚"判断：仅在 18:00-06:00 内触发。便于演示联动效果。
  onlyAtNight?: boolean
}

export interface RuleTrigger {
  sensorId: string      // 传感器 ID；'__any__' 表示任意传感器
  event: RuleTriggerEvent
}

export interface IfThisRule {
  id: string              // 'rule_welcome_home'
  name: string            // '回家自动亮灯'
  enabled: boolean
  trigger: RuleTrigger
  condition: RuleCondition
  actions: RuleAction[]
  lastFiredTime: number   // 0 表示从未触发
  fireCount: number       // 累计触发次数
}

// ==================== UI 展示用的聚合视图 ====================
export interface RuleSummary {
  rule: IfThisRule
  triggerDesc: string    // 例如 "客厅红外 · 检测到人"
  conditionDesc: string  // 例如 "仅夜间"
  actionDesc: string     // 例如 "打开 客厅灯组（亮度80）"
}