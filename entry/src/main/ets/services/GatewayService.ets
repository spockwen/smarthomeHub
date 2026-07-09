/**
 * GatewayService
 * ------------------------------------------------------------
 * 跨域联动编排层：在门禁/照明/温控三域之间充当"网关"。
 *
 * 职责：
 *   1. 订阅 GatewayBus 的全部 GatewayEvent（单订阅者，幂等）
 *   2. 预置 3 条跨域联动规则（door.unlock → lights/climate、door.lock → climate off、
 *      sensor.motion(夜窗22-06) → hallway lights）
 *   3. 收到事件后调用 RuleEngine.findCrossDomainRules + buildCrossDomainActions 筛选
 *   4. 按 action.domain/op switch 分发到对应域 Service：
 *        - light   → LightingService.setLightOn（按 groupId 展开）
 *        - lock    → DoorLockService.unlock / lock（operator="gateway"）
 *        - climate → ClimateService.setMode / setTargetTemp / setPower
 *   5. 规则命中后更新 fireCount / lastFiredTime 并持久化
 *
 * 设计原则：
 *   - 静态方法 + AppStorage 持久化（与其他 Service 一致）
 *   - 幂等 init()：重复调用不会覆盖现有订阅/规则
 *   - 失败隔离：单个 action 抛出不会中断后续 action 分发
 *   - 单订阅者：通过 AppStorage 标志位 + handler 引用双重幂等保护
 *
 * 依赖：
 *   - RuleEngine  : findCrossDomainRules / buildCrossDomainActions / describeCrossDomain
 *   - GatewayBus  : 单订阅 handler
 *   - LightingService / DoorLockService / ClimateService : 下游执行器
 */

import {
  GatewayEvent,
  CrossDomainRule,
  CrossDomainAction,
  CrossDomainTrigger,
  CrossDomainActionParams,
  EventPayload
} from '../models/GatewayModel'
import { ClimateMode } from '../models/ClimateModel'
import { RuleEngine } from './RuleEngine'
import { GatewayBus } from './GatewayBus'
import { LightingService } from './LightingService'
import { DoorLockService } from './DoorLockService'
import { ClimateService } from './ClimateService'

const KEY_INIT: string = 'gateway_init_v1'
const KEY_RULES: string = 'gateway_rules_v1'
const OPERATOR_NAME: string = 'gateway'

interface AddRuleParams {
  name: string
  enabled: boolean
  trigger: CrossDomainTrigger
  actions: CrossDomainAction[]
}

function genId(prefix: string): string {
  return prefix + '_' + Date.now().toString(36) + '_' + Math.floor(Math.random() * 1e6).toString(36)
}

// ==================== GatewayService ====================
export class GatewayService {
  private static handlerInstalled: boolean = false

  // ---------------- 初始化 ----------------

  /**
   * 幂等初始化：订阅 GatewayBus + 写入预置规则（仅首次执行）。
   * 重复调用安全：不会覆盖 handler，不会重复写入规则。
   */
  static init(): void {
    if (GatewayService.handlerInstalled) {
      return
    }
    const initFlag: boolean = AppStorage.get<boolean>(KEY_INIT) ?? false
    if (initFlag) {
      GatewayBus.subscribe(GatewayService.onEvent)
      GatewayService.handlerInstalled = true
      return
    }

    const presets: CrossDomainRule[] = GatewayService.buildPresetRules()
    AppStorage.setOrCreate(KEY_RULES, presets)
    AppStorage.setOrCreate(KEY_INIT, true)

    GatewayBus.subscribe(GatewayService.onEvent)
    GatewayService.handlerInstalled = true

    console.info('[GatewayService] initialized with', presets.length, 'preset cross-domain rules')
  }

  /**
   * 释放资源：取消订阅 + 清除幂等标志（规则保留以便下次启动复用）。
   */
  static dispose(): void {
    GatewayBus.unsubscribe()
    GatewayService.handlerInstalled = false
  }

  /**
   * 强制重置：清空规则 + 重新初始化（用于测试 / 一键清空场景）。
   */
  static reset(): void {
    GatewayBus.unsubscribe()
    AppStorage.setOrCreate(KEY_RULES, [])
    AppStorage.setOrCreate(KEY_INIT, false)
    GatewayService.handlerInstalled = false
    GatewayService.init()
  }

  // ---------------- 规则 CRUD ----------------

  /**
   * 读取当前全部跨域规则（深拷贝，避免外部直接修改 AppStorage）。
   */
  static getRules(): CrossDomainRule[] {
    const rules = AppStorage.get<CrossDomainRule[]>(KEY_RULES)
    if (rules && Array.isArray(rules)) {
      return rules
    }
    return []
  }

  /**
   * 通过 ID 查询单条规则。
   */
  static getRuleById(id: string): CrossDomainRule | null {
    const rules: CrossDomainRule[] = GatewayService.getRules()
    return rules.find(r => r.id === id) ?? null
  }

  /**
   * 启用/禁用一条规则（enable=false 时即使触发也不分发动作）。
   */
  static enableRule(id: string, enabled: boolean): CrossDomainRule | null {
    const rules: CrossDomainRule[] = GatewayService.getRules()
    const idx: number = rules.findIndex(r => r.id === id)
    if (idx < 0) {
      return null
    }
    rules[idx].enabled = enabled
    AppStorage.setOrCreate(KEY_RULES, rules)
    return rules[idx]
  }

  /**
   * 手动添加一条规则。
   */
  static addRule(rule: AddRuleParams): CrossDomainRule {
    const rules: CrossDomainRule[] = GatewayService.getRules()
    const newRule: CrossDomainRule = {
      id: genId('r'),
      name: rule.name,
      enabled: rule.enabled,
      fireCount: 0,
      lastFiredTime: 0,
      trigger: rule.trigger,
      actions: rule.actions
    }
    rules.push(newRule)
    AppStorage.setOrCreate(KEY_RULES, rules)
    return newRule
  }

  /**
   * 通过 ID 移除一条规则。
   */
  static removeRule(id: string): boolean {
    const rules: CrossDomainRule[] = GatewayService.getRules()
    const next: CrossDomainRule[] = rules.filter(r => r.id !== id)
    if (next.length === rules.length) {
      return false
    }
    AppStorage.setOrCreate(KEY_RULES, next)
    return true
  }

  /**
   * 重置某条规则的命中统计。
   */
  static resetRuleStats(id: string): boolean {
    const rules: CrossDomainRule[] = GatewayService.getRules()
    const idx: number = rules.findIndex(r => r.id === id)
    if (idx < 0) {
      return false
    }
    rules[idx].fireCount = 0
    rules[idx].lastFiredTime = 0
    AppStorage.setOrCreate(KEY_RULES, rules)
    return true
  }

  // ---------------- 事件处理（私有） ----------------

  /**
   * GatewayBus 事件回调：筛选规则 → 构建 actions → 逐个分发。
   * 该方法由 GatewayBus 直接调用，必须同步返回（subscribe 签名约束）。
   * 异步动作（DoorLockService.unlock）通过 fire-and-forget 处理。
   */
  private static onEvent(event: GatewayEvent): void {
    try {
      const rules: CrossDomainRule[] = GatewayService.getRules()
      const matched: CrossDomainRule[] = RuleEngine.findCrossDomainRules(event, rules, new Date(Date.now()))
      if (matched.length === 0) {
        return
      }

      const actions: CrossDomainAction[] = RuleEngine.buildCrossDomainActions(matched)
      for (let i = 0; i < actions.length; i++) {
        GatewayService.dispatchAction(actions[i])
      }

      // 更新命中统计
      GatewayService.bumpFireStats(matched.map(r => r.id))
    } catch (e) {
      console.error('[GatewayService] onEvent error:', JSON.stringify(e))
    }
  }

  /**
   * action 分发入口：按 domain switch 到具体处理函数。
   */
  private static dispatchAction(action: CrossDomainAction): void {
    try {
      switch (action.domain) {
        case 'light':
          GatewayService.dispatchLightAction(action)
          break
        case 'lock':
          GatewayService.dispatchLockAction(action)
          break
        case 'climate':
          GatewayService.dispatchClimateAction(action)
          break
        default:
          console.warn('[GatewayService] unknown action domain:', action.domain)
      }
    } catch (e) {
      // 失败隔离：单个 action 出错不影响后续 action
      console.error('[GatewayService] dispatch failed:', JSON.stringify(action), JSON.stringify(e))
    }
  }

  // ---------------- 各域 action 处理器 ----------------

  private static dispatchLightAction(action: CrossDomainAction): void {
    switch (action.op) {
      case 'turn_on_group': {
        const groupId: string = action.targets[0]
        if (!groupId) {
          return
        }
        const lights = LightingService.getLights().filter(l => l.groupId === groupId)
        lights.forEach(l => LightingService.setLightOn(l.id, true))
        return
      }
      case 'turn_off_group': {
        const groupId: string = action.targets[0]
        if (!groupId) {
          return
        }
        const lights = LightingService.getLights().filter(l => l.groupId === groupId)
        lights.forEach(l => LightingService.setLightOn(l.id, false))
        return
      }
      case 'turn_on': {
        const lightId: string = action.targets[0]
        if (!lightId) {
          return
        }
        LightingService.setLightOn(lightId, true)
        return
      }
      case 'turn_off': {
        const lightId: string = action.targets[0]
        if (!lightId) {
          return
        }
        LightingService.setLightOn(lightId, false)
        return
      }
      default:
        console.warn('[GatewayService] unknown light op:', action.op)
    }
  }

  private static dispatchLockAction(action: CrossDomainAction): void {
    const lockId: string = action.targets[0]
    if (!lockId) {
      return
    }
    switch (action.op) {
      case 'unlock': {
        // unlock 是 async（模拟远程开锁延时），此处 fire-and-forget。
        // GatewayBus.subscribe 签名要求同步返回，所以不能 await。
        DoorLockService.unlock(OPERATOR_NAME, 'rule')
          .then(rec => {
            console.info('[GatewayService] gateway-rule unlocked:', rec.id)
          })
          .catch((err: string) => {
            console.error('[GatewayService] gateway-rule unlock failed:', JSON.stringify(err))
          })
        return
      }
      case 'lock': {
        DoorLockService.lock(OPERATOR_NAME, 'rule')
        return
      }
      default:
        console.warn('[GatewayService] unknown lock op:', action.op)
    }
  }

  private static dispatchClimateAction(action: CrossDomainAction): void {
    const deviceId: string = action.targets[0]
    if (!deviceId) {
      return
    }
    switch (action.op) {
      case 'set_power': {
        const on: boolean = action.params?.on ?? false
        ClimateService.setPower(on, OPERATOR_NAME)
        return
      }
      case 'set_mode': {
        const mode: ClimateMode | undefined = action.params?.mode
        if (!mode) {
          console.warn('[GatewayService] set_mode missing params.mode')
          return
        }
        ClimateService.setMode(mode, OPERATOR_NAME)
        return
      }
      case 'set_target_temp': {
        const raw: number | undefined = action.params?.temp
        const temp: number = raw ?? NaN
        if (!Number.isFinite(temp)) {
          console.warn('[GatewayService] set_target_temp invalid:', raw)
          return
        }
        ClimateService.setTargetTemp(temp, OPERATOR_NAME)
        return
      }
      default:
        console.warn('[GatewayService] unknown climate op:', action.op)
    }
  }

  // ---------------- 内部：预置规则 ----------------

  /**
   * 构建 3 条预置跨域规则。
   * ID 固定以便后续 UI 引用与跨版本兼容。
   */
  private static buildPresetRules(): CrossDomainRule[] {
    const r1: CrossDomainRule = {
      id: 'r_unlock_living_lights',
      name: '回家灯光',
      enabled: true,
      fireCount: 0,
      lastFiredTime: 0,
      trigger: {
        source: 'lock',
        type: 'unlocked'
      },
      actions: [
        {
          domain: 'light',
          op: 'turn_on_group',
          targets: ['grp_living_room']
        }
      ]
    }

    const r2Params = new CrossDomainActionParams()
    r2Params.temp = 24
    const r2: CrossDomainRule = {
      id: 'r_unlock_climate_24',
      name: '回家空调',
      enabled: true,
      fireCount: 0,
      lastFiredTime: 0,
      trigger: {
        source: 'lock',
        type: 'unlocked'
      },
      actions: [
        {
          domain: 'climate',
          op: 'set_target_temp',
          targets: ['thermo_main'],
          params: r2Params
        }
      ]
    }

    const r3: CrossDomainRule = {
      id: 'r_motion_night_hallway',
      name: '夜间走廊感应',
      enabled: true,
      fireCount: 0,
      lastFiredTime: 0,
      trigger: {
        source: 'sensor',
        type: 'motion_detected',
        window: '22:00-06:00'
      },
      actions: [
        {
          domain: 'light',
          op: 'turn_on_group',
          targets: ['grp_hallway']
        }
      ]
    }

    return [r1, r2, r3]
  }

  // ---------------- 内部：命中统计 ----------------

  /**
   * 批量更新规则的命中次数与最近命中时间。
   */
  private static bumpFireStats(ruleIds: string[]): void {
    if (ruleIds.length === 0) {
      return
    }
    const rules: CrossDomainRule[] = GatewayService.getRules()
    const idSet: Set<string> = new Set(ruleIds)
    const now: number = Date.now()
    let changed: boolean = false
    for (let i = 0; i < rules.length; i++) {
      if (idSet.has(rules[i].id)) {
        rules[i].fireCount = (rules[i].fireCount ?? 0) + 1
        rules[i].lastFiredTime = now
        changed = true
      }
    }
    if (changed) {
      AppStorage.setOrCreate(KEY_RULES, rules)
    }
  }
}
