/**
 * 联动规则引擎（纯逻辑层，无 UI、无 IO）
 *
 * 职责：
 *   1. 根据触发事件筛选出应被激活的规则
 *   2. 检查规则的前置条件（时间窗口、是否仅夜间等）
 *   3. 计算执行动作后灯组应处的目标状态
 *
 * 设计原则：
 *   - 纯函数：仅依赖入参；调用方负责把结果写回 AppStorage。
 *   - 可单元测试：所有方法对 time/now 都有可注入参数。
 */

import {
  IfThisRule,
  RuleAction,
  TriggerEvent,
  RuleSummary,
  Light,
  MotionSensor
} from '../models/LightingModel'
import {
  CrossDomainRule,
  CrossDomainAction,
  GatewayEvent
} from '../models/GatewayModel'

export class RuleEngine {

  /**
   * 把 HH:mm 字符串转换为当日分钟数（0-1439）。
   * 解析失败返回 -1。
   */
  static toMinutes(hhmm: string | undefined): number {
    if (!hhmm || hhmm.length < 4) return -1
    const parts = hhmm.split(':')
    if (parts.length !== 2) return -1
    const h = parseInt(parts[0], 10)
    const m = parseInt(parts[1], 10)
    if (isNaN(h) || isNaN(m) || h < 0 || h > 23 || m < 0 || m > 59) return -1
    return h * 60 + m
  }

  /**
   * 判断给定 Date 是否落在规则的时间窗口内。
   * 支持跨夜（例如 22:00-06:00）。
   */
  static isWithinTimeWindow(
    rule: IfThisRule,
    now: Date
  ): boolean {
    const c = rule.condition
    const from = RuleEngine.toMinutes(c.timeFrom)
    const to = RuleEngine.toMinutes(c.timeTo)
    if (from < 0 || to < 0) {
      // 未配置时间窗口则不限制
    } else {
      const cur = now.getHours() * 60 + now.getMinutes()
      const inWindow = from <= to
        ? (cur >= from && cur <= to)
        : (cur >= from || cur <= to) // 跨夜
      if (!inWindow) return false
    }

    if (c.onlyAtNight) {
      const h = now.getHours()
      // 18:00-次日 06:00 视为夜间
      if (h >= 6 && h < 18) return false
    }
    return true
  }

  /**
   * 在规则集合中筛出当前事件 + 当前时间下应被激活的规则。
   */
  static findMatching(
    event: TriggerEvent,
    rules: IfThisRule[],
    now: Date
  ): IfThisRule[] {
    const result: IfThisRule[] = []
    for (const rule of rules) {
      if (!rule.enabled) continue
      if (rule.trigger.event !== event.type) continue
      if (rule.trigger.sensorId !== '__any__' && rule.trigger.sensorId !== event.sensorId) continue
      if (!RuleEngine.isWithinTimeWindow(rule, now)) continue
      result.push(rule)
    }
    return result
  }

  /**
   * 把规则动作应用到灯列表上，返回更新后的灯列表（不可变风格：返回新数组）。
   * 这里仅做状态计算，写回由 LightingService 负责。
   */
  static applyActions(
    rules: IfThisRule[],
    lights: Light[]
  ): Light[] {
    // 复制避免直接修改入参
    const map = new Map<string, Light>()
    lights.forEach(l => map.set(l.id, {
      id: l.id,
      name: l.name,
      room: l.room,
      groupId: l.groupId,
      isOn: l.isOn,
      brightness: l.brightness
    }))

    for (const rule of rules) {
      for (const action of rule.actions) {
        RuleEngine.applyAction(action, map)
      }
    }

    return Array.from(map.values())
  }

  private static applyAction(action: RuleAction, map: Map<string, Light>): void {
    switch (action.type) {
      case 'turn_on':
        for (const id of action.targetIds) {
          const l = map.get(id)
          if (!l) continue
          l.isOn = true
          if (typeof action.brightness === 'number') {
            l.brightness = Math.max(0, Math.min(100, action.brightness))
          }
        }
        break
      case 'turn_off':
        for (const id of action.targetIds) {
          const l = map.get(id)
          if (!l) continue
          l.isOn = false
        }
        break
      case 'toggle':
        for (const id of action.targetIds) {
          const l = map.get(id)
          if (!l) continue
          l.isOn = !l.isOn
        }
        break
      case 'turn_on_group':
        // targetIds 是灯组 ID，需要调用方先展开——这里仅标记，LightingService 处理
        // 引擎层仅做"按 id 列表"操作；group 展开放在 Service 层
        for (const gid of action.targetIds) {
          // 在 Light 上 groupId 匹配
          for (const l of map.values()) {
            if (l.groupId === gid) {
              l.isOn = true
              if (typeof action.brightness === 'number') {
                l.brightness = Math.max(0, Math.min(100, action.brightness))
              }
            }
          }
        }
        break
      default:
        break
    }
  }

  /**
   * 生成人类可读的规则摘要文本，供 UI 展示。
   */
  static describe(
    rule: IfThisRule,
    sensors: MotionSensor[]
  ): RuleSummary {
    const sensor = sensors.find(s => s.id === rule.trigger.sensorId)
    const sensorName = rule.trigger.sensorId === '__any__'
      ? '任意传感器'
      : (sensor ? sensor.name : rule.trigger.sensorId)

    const eventText = rule.trigger.event === 'motion_detected' ? '检测到人' : '人离开'

    const triggerDesc = `${sensorName} · ${eventText}`

    const cond: string[] = []
    if (rule.condition.timeFrom && rule.condition.timeTo) {
      cond.push(`${rule.condition.timeFrom} - ${rule.condition.timeTo}`)
    }
    if (rule.condition.onlyAtNight) {
      cond.push('仅夜间')
    }
    const conditionDesc = cond.length === 0 ? '不限' : cond.join(' / ')

    const actionDesc = rule.actions.map(a => {
      switch (a.type) {
        case 'turn_on': return `打开灯(${a.targetIds.length}盏${a.brightness != null ? `, 亮度${a.brightness}` : ''})`
        case 'turn_off': return `关闭灯(${a.targetIds.length}盏)`
        case 'toggle': return `切换灯(${a.targetIds.length}盏)`
        case 'turn_on_group': return `打开灯组(${a.targetIds.length}组${a.brightness != null ? `, 亮度${a.brightness}` : ''})`
        default: return '未知动作'
      }
    }).join('；')

    return { rule, triggerDesc, conditionDesc, actionDesc }
  }

  // ============================================================
  //                跨域规则（Cross-Domain Rules）
  // ============================================================

  /**
   * 判断 HH:mm 时间字符串（"from-to" 形式）是否在给定的 Date 上生效。
   * 复用 RuleEngine.toMinutes，支持跨夜窗口。
   * 返回 true 表示该规则的时间窗口满足 / 未配置。
   */
  static isCrossDomainWindowMatch(window: string | undefined, now: Date): boolean {
    if (!window) return true
    const parts = window.split('-')
    if (parts.length !== 2) return true
    const from = RuleEngine.toMinutes(parts[0].trim())
    const to = RuleEngine.toMinutes(parts[1].trim())
    if (from < 0 || to < 0) return true
    const cur = now.getHours() * 60 + now.getMinutes()
    return from <= to
      ? (cur >= from && cur <= to)
      : (cur >= from || cur <= to) // 跨夜
  }

  /**
   * 跨域规则匹配：给定事件 + 规则集 + 当前时间，筛出应触发的跨域规则。
   * - 仅匹配 enabled = true
   * - 仅匹配 source + type 相同
   * - 检查 trigger.window 时间窗口
   */
  static findCrossDomainRules(
    event: GatewayEvent,
    rules: CrossDomainRule[],
    now: Date
  ): CrossDomainRule[] {
    const result: CrossDomainRule[] = []
    for (const rule of rules) {
      if (!rule.enabled) continue
      if (rule.trigger.source !== event.source) continue
      if (rule.trigger.type !== event.type) continue
      if (!RuleEngine.isCrossDomainWindowMatch(rule.trigger.window, now)) continue
      result.push(rule)
    }
    return result
  }

  /**
   * 把跨域规则的动作扁平化收集成 CrossDomainAction[]。
   * 上层 GatewayService 再按 domain 派发到对应 service。
   */
  static buildCrossDomainActions(rules: CrossDomainRule[]): CrossDomainAction[] {
    const out: CrossDomainAction[] = []
    for (const r of rules) {
      for (const a of r.actions) {
        out.push(a)
      }
    }
    return out
  }

  /**
   * 跨域规则描述（中文，UI 展示用）。
   * 例："门锁开锁 → 打开客厅灯组 + 空调设为 24℃"
   */
  static describeCrossDomain(rule: CrossDomainRule): string {
    const trig = `${rule.trigger.source}·${rule.trigger.type}` +
      (rule.trigger.window ? `（${rule.trigger.window}）` : '')
    const acts = rule.actions.map(a => {
      const p = a.params ? JSON.stringify(a.params) : ''
      return `${a.domain}/${a.op} -> [${a.targets.join(', ')}] ${p}`
    }).join('；')
    return `${trig} → ${acts}（已触发 ${rule.fireCount} 次）`
  }
}