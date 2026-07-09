/**
 * 智能照明中心 - 服务层
 *
 * 职责：
 *   - AppStorage 初始化与持久化（key: lighting_lights / lighting_sensors / lighting_rules / lighting_last_event）
 *   - 暴露 CRUD 接口给 UI
 *   - 接收模拟触发事件 → 调用 RuleEngine 计算结果 → 写回 AppStorage
 *
 * 设计原则：
 *   - 单例风格（静态方法）
 *   - 所有 setter 同步触发持久化
 *   - 模拟事件仅修改本地状态，不进行任何网络外发
 */

import {
  Light,
  LightGroup,
  MotionSensor,
  IfThisRule,
  RuleTrigger,
  TriggerEvent,
  RuleAction
} from '../models/LightingModel'
import { RuleEngine } from './RuleEngine'

// ==================== AppStorage Key ====================
const K_LIGHTS = 'lighting_lights'
const K_SENSORS = 'lighting_sensors'
const K_RULES = 'lighting_rules'
const K_GROUPS = 'lighting_groups'
const K_LAST_EVENT = 'lighting_last_event'

// ==================== 结果类型 ====================
export interface SimulateMotionResult {
  firedRuleIds: string[]
  event: TriggerEvent
}

export interface SimulateAllResult {
  firedRuleIds: string[]
  events: TriggerEvent[]
}

// ==================== 默认数据 ====================
function defaultGroups(): LightGroup[] {
  return [
    { id: 'group_living', name: '客厅灯组', room: '客厅' },
    { id: 'group_bedroom', name: '卧室灯组', room: '卧室' },
    { id: 'group_kitchen', name: '厨房灯组', room: '厨房' }
  ]
}

function defaultLights(): Light[] {
  return [
    { id: 'light_living_main', name: '客厅吊灯', room: '客厅', groupId: 'group_living', isOn: false, brightness: 80 },
    { id: 'light_living_amb',  name: '客厅氛围灯', room: '客厅', groupId: 'group_living', isOn: true,  brightness: 40 },
    { id: 'light_bedroom_main', name: '卧室主灯', room: '卧室', groupId: 'group_bedroom', isOn: false, brightness: 60 },
    { id: 'light_bedroom_night', name: '卧室夜灯', room: '卧室', groupId: 'group_bedroom', isOn: true, brightness: 20 },
    { id: 'light_kitchen_main', name: '厨房主灯', room: '厨房', groupId: 'group_kitchen', isOn: false, brightness: 100 }
  ]
}

function defaultSensors(): MotionSensor[] {
  return [
    { id: 'sensor_living',  name: '客厅红外',  room: '客厅', detected: false, lastTriggerTime: 0 },
    { id: 'sensor_bedroom', name: '卧室红外',  room: '卧室', detected: false, lastTriggerTime: 0 },
    { id: 'sensor_kitchen', name: '厨房红外',  room: '厨房', detected: false, lastTriggerTime: 0 }
  ]
}

function defaultRules(): IfThisRule[] {
  const r1: IfThisRule = {
    id: 'rule_welcome_home',
    name: '回家自动亮灯',
    enabled: true,
    trigger: { sensorId: 'sensor_living', event: 'motion_detected' },
    condition: { onlyAtNight: true },
    actions: [
      { type: 'turn_on_group', targetIds: ['group_living'], brightness: 80 }
    ],
    lastFiredTime: 0,
    fireCount: 0
  }
  const r2: IfThisRule = {
    id: 'rule_bedroom_soft',
    name: '卧室起夜柔光',
    enabled: true,
    trigger: { sensorId: 'sensor_bedroom', event: 'motion_detected' },
    condition: { timeFrom: '22:00', timeTo: '06:00' },
    actions: [
      { type: 'turn_on', targetIds: ['light_bedroom_night'], brightness: 30 }
    ],
    lastFiredTime: 0,
    fireCount: 0
  }
  const r3: IfThisRule = {
    id: 'rule_leave_off',
    name: '离开自动关灯',
    enabled: true,
    trigger: { sensorId: '__any__', event: 'motion_cleared' },
    condition: {},
    actions: [
      { type: 'turn_off', targetIds: ['light_living_main', 'light_kitchen_main'] }
    ],
    lastFiredTime: 0,
    fireCount: 0
  }
  const r4: IfThisRule = {
    id: 'rule_kitchen_welcome',
    name: '进厨房自动开灯',
    enabled: false,
    trigger: { sensorId: 'sensor_kitchen', event: 'motion_detected' },
    condition: {},
    actions: [
      { type: 'turn_on', targetIds: ['light_kitchen_main'], brightness: 100 }
    ],
    lastFiredTime: 0,
    fireCount: 0
  }
  return [r1, r2, r3, r4]
}

// ==================== 内部工具 ====================
function readJson<T>(key: string, fallback: T): T {
  const raw = AppStorage.get<string>(key)
  if (!raw) return fallback
  try {
    const parsed = JSON.parse(raw) as T
    return parsed
  } catch (e) {
    return fallback
  }
}

function writeJson<T>(key: string, value: T): void {
  AppStorage.setOrCreate(key, JSON.stringify(value))
}

function clone<T>(v: T): T {
  return JSON.parse(JSON.stringify(v)) as T
}

// ==================== 服务主体 ====================
export class LightingService {

  /**
   * 初始化：首次启动写入默认值；后续启动保留已有数据。
   */
  static initialize(): void {
    if (!AppStorage.get<string>(K_LIGHTS)) {
      writeJson(K_LIGHTS, defaultLights())
    }
    if (!AppStorage.get<string>(K_SENSORS)) {
      writeJson(K_SENSORS, defaultSensors())
    }
    if (!AppStorage.get<string>(K_RULES)) {
      writeJson(K_RULES, defaultRules())
    }
    if (!AppStorage.get<string>(K_GROUPS)) {
      writeJson(K_GROUPS, defaultGroups())
    }
    if (!AppStorage.get<string>(K_LAST_EVENT)) {
      AppStorage.setOrCreate(K_LAST_EVENT, '')
    }
  }

  // ---------- 查询 ----------
  static getGroups(): LightGroup[] {
    return readJson<LightGroup[]>(K_GROUPS, defaultGroups())
  }

  static getLights(): Light[] {
    return readJson<Light[]>(K_LIGHTS, defaultLights())
  }

  static getLightsByGroup(groupId: string): Light[] {
    return LightingService.getLights().filter(l => l.groupId === groupId)
  }

  static getSensors(): MotionSensor[] {
    return readJson<MotionSensor[]>(K_SENSORS, defaultSensors())
  }

  static getRules(): IfThisRule[] {
    return readJson<IfThisRule[]>(K_RULES, defaultRules())
  }

  static getLastEvent(): TriggerEvent | null {
    const raw = AppStorage.get<string>(K_LAST_EVENT)
    if (!raw) return null
    try {
      return JSON.parse(raw) as TriggerEvent
    } catch (e) {
      return null
    }
  }

  // ---------- 灯操作 ----------
  static toggleLight(id: string): void {
    const lights = LightingService.getLights()
    const idx = lights.findIndex(l => l.id === id)
    if (idx < 0) return
    const cur = lights[idx]
    lights[idx] = { id: cur.id, name: cur.name, room: cur.room, groupId: cur.groupId, isOn: !cur.isOn, brightness: cur.brightness }
    writeJson(K_LIGHTS, lights)
  }

  static setLightOn(id: string, on: boolean): void {
    const lights = LightingService.getLights()
    const idx = lights.findIndex(l => l.id === id)
    if (idx < 0) return
    const cur = lights[idx]
    lights[idx] = { id: cur.id, name: cur.name, room: cur.room, groupId: cur.groupId, isOn: on, brightness: cur.brightness }
    writeJson(K_LIGHTS, lights)
  }

  static setBrightness(id: string, value: number): void {
    const lights = LightingService.getLights()
    const idx = lights.findIndex(l => l.id === id)
    if (idx < 0) return
    const v = Math.max(0, Math.min(100, value))
    const cur = lights[idx]
    lights[idx] = { id: cur.id, name: cur.name, room: cur.room, groupId: cur.groupId, isOn: v > 0, brightness: v }
    writeJson(K_LIGHTS, lights)
  }

  static toggleGroup(groupId: string): void {
    const lights = LightingService.getLights()
    const inGroup = lights.filter(l => l.groupId === groupId)
    if (inGroup.length === 0) return
    const allOn = inGroup.every(l => l.isOn)
    const next = !allOn
    const updated: Light[] = lights.map((l: Light): Light => {
      if (l.groupId === groupId) {
        return { id: l.id, name: l.name, room: l.room, groupId: l.groupId, isOn: next, brightness: l.brightness }
      }
      return l
    })
    writeJson(K_LIGHTS, updated)
  }

  // ---------- 规则操作 ----------
  static toggleRule(id: string): void {
    const rules = LightingService.getRules()
    const idx = rules.findIndex(r => r.id === id)
    if (idx < 0) return
    const cur = rules[idx]
    rules[idx] = { id: cur.id, name: cur.name, enabled: !cur.enabled, trigger: cur.trigger, condition: cur.condition, actions: cur.actions, lastFiredTime: cur.lastFiredTime, fireCount: cur.fireCount }
    writeJson(K_RULES, rules)
  }

  static setRuleEnabled(id: string, enabled: boolean): void {
    const rules = LightingService.getRules()
    const idx = rules.findIndex(r => r.id === id)
    if (idx < 0) return
    const cur = rules[idx]
    rules[idx] = { id: cur.id, name: cur.name, enabled: enabled, trigger: cur.trigger, condition: cur.condition, actions: cur.actions, lastFiredTime: cur.lastFiredTime, fireCount: cur.fireCount }
    writeJson(K_RULES, rules)
  }

  // ---------- 传感器 / 事件 ----------
  /**
   * 模拟传感器检测到人：更新传感器状态、生成事件、调用规则引擎。
   * 返回被触发的规则 id 列表与最后的灯组状态，便于 UI 提示。
   */
  static simulateMotion(sensorId: string): SimulateMotionResult {
    const event: TriggerEvent = { type: 'motion_detected', sensorId, timestamp: Date.now() }
    const sensors = LightingService.getSensors()
    const idx = sensors.findIndex(s => s.id === sensorId)
    if (idx < 0) {
      return { firedRuleIds: [], event: event }
    }
    const cur = sensors[idx]
    sensors[idx] = { id: cur.id, name: cur.name, room: cur.room, detected: true, lastTriggerTime: event.timestamp }
    writeJson(K_SENSORS, sensors)

    const firedRuleIds = LightingService.handleEvent(event)
    return { firedRuleIds: firedRuleIds, event: event }
  }

  /**
   * 模拟人离开：更新传感器状态、生成 motion_cleared 事件、调用规则引擎。
   */
  static clearMotion(sensorId: string): SimulateMotionResult {
    const event: TriggerEvent = { type: 'motion_cleared', sensorId, timestamp: Date.now() }
    const sensors = LightingService.getSensors()
    const idx = sensors.findIndex(s => s.id === sensorId)
    if (idx < 0) {
      return { firedRuleIds: [], event: event }
    }
    const cur = sensors[idx]
    sensors[idx] = { id: cur.id, name: cur.name, room: cur.room, detected: false, lastTriggerTime: cur.lastTriggerTime }
    writeJson(K_SENSORS, sensors)

    const firedRuleIds = LightingService.handleEvent(event)
    return { firedRuleIds: firedRuleIds, event: event }
  }

  /**
   * 一键模拟"有人回家"：把所有传感器标记为 detected、依次派发事件。
   */
  static simulateAllSensorsMotion(): SimulateAllResult {
    const sensors = LightingService.getSensors()
    const now = Date.now()
    const updated: MotionSensor[] = sensors.map((s: MotionSensor): MotionSensor => {
      return { id: s.id, name: s.name, room: s.room, detected: true, lastTriggerTime: now }
    })
    writeJson(K_SENSORS, updated)

    const allFired = new Set<string>()
    const events: TriggerEvent[] = []
    for (const s of updated) {
      const ev: TriggerEvent = { type: 'motion_detected', sensorId: s.id, timestamp: now }
      events.push(ev)
      LightingService.handleEvent(ev).forEach(id => allFired.add(id))
    }
    return { firedRuleIds: Array.from(allFired), events: events }
  }

  /**
   * 一键模拟"全部离开"：把所有传感器标记为未检测。
   */
  static simulateAllSensorsClear(): SimulateAllResult {
    const sensors = LightingService.getSensors()
    const updated: MotionSensor[] = sensors.map((s: MotionSensor): MotionSensor => {
      return { id: s.id, name: s.name, room: s.room, detected: false, lastTriggerTime: s.lastTriggerTime }
    })
    writeJson(K_SENSORS, updated)

    const allFired = new Set<string>()
    const events: TriggerEvent[] = []
    for (const s of updated) {
      const ev: TriggerEvent = { type: 'motion_cleared', sensorId: s.id, timestamp: Date.now() }
      events.push(ev)
      LightingService.handleEvent(ev).forEach(id => allFired.add(id))
    }
    return { firedRuleIds: Array.from(allFired), events: events }
  }

  /**
   * 处理事件：匹配规则 → 计算灯状态 → 写回 AppStorage。
   * 返回被触发的规则 id 列表。
   */
  private static handleEvent(event: TriggerEvent): string[] {
    const rules = LightingService.getRules()
    const matched = RuleEngine.findMatching(event, rules, new Date(event.timestamp))
    if (matched.length === 0) {
      // 即使无规则匹配，也记录最近事件
      AppStorage.setOrCreate(K_LAST_EVENT, JSON.stringify(event))
      return []
    }

    // 记录最近事件
    AppStorage.setOrCreate(K_LAST_EVENT, JSON.stringify(event))

    // 应用动作到灯
    const newLights = RuleEngine.applyActions(matched, LightingService.getLights())
    writeJson(K_LIGHTS, newLights)

    // 更新规则的触发统计
    const updatedRules: IfThisRule[] = rules.map((r: IfThisRule): IfThisRule => {
      if (matched.find(m => m.id === r.id)) {
        return { id: r.id, name: r.name, enabled: r.enabled, trigger: r.trigger, condition: r.condition, actions: r.actions, lastFiredTime: event.timestamp, fireCount: r.fireCount + 1 }
      }
      return r
    })
    writeJson(K_RULES, updatedRules)

    return matched.map(r => r.id)
  }

  /**
   * 重置为默认数据（演示用）
   */
  static resetAll(): void {
    writeJson(K_LIGHTS, defaultLights())
    writeJson(K_SENSORS, defaultSensors())
    writeJson(K_RULES, defaultRules())
    writeJson(K_GROUPS, defaultGroups())
    AppStorage.setOrCreate(K_LAST_EVENT, '')
  }
}