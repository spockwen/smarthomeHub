/**
 * DoorLockService
 * ------------------------------------------------------------
 * 门锁业务服务：负责门禁状态管理、解锁日志记录、跨域事件发布。
 *
 * 职责：
 *   1. 维护 DoorLockStateRecord（AppStorage 持久化，key = door_lock_state）
 *   2. 记录开锁日志（AppStorage 持久化，key = doorUnlockLogs —— 保留历史 key 兼容）
 *   3. 解锁/上锁时通过 GatewayBus 发布跨域事件（LockEventType）
 *   4. 提供异步 unlock() 模拟远程开锁延时
 *
 * 设计原则：
 *   - Service 静态方法 + AppStorage 持久化
 *   - ID 三段式：source·type·seq
 *   - 日志最新在前，最多 20 条
 */

import {
  DoorLockStateRecord,
  DoorLockState,
  UnlockLogEntry,
  UnlockResult
} from '../models/DoorLockModel'
import { GatewayEvent, EventPayload } from '../models/GatewayModel'
import { GatewayBus } from './GatewayBus'

// ==================== 常量 ====================
const KEY_STATE: string = 'door_lock_state'
const KEY_LOGS: string = 'doorUnlockLogs'  // 保留历史 key 兼容老版本
const MAX_LOGS: number = 20
const UNLOCK_DELAY_MS: number = 1200       // 模拟远程开锁网络延时

const DOORLOCK_ID: string = 'doorlock_front'
const DOORLOCK_NAME: string = '前门门锁'

export class DoorLockService {

  // ----------------- 状态读写 -----------------

  static getState(): DoorLockStateRecord {
    const stored = AppStorage.get<DoorLockStateRecord>(KEY_STATE)
    if (stored) return stored
    const init: DoorLockStateRecord = {
      id: DOORLOCK_ID,
      name: DOORLOCK_NAME,
      state: 'locked' as DoorLockState,
      battery: 100,
      updatedAt: Date.now()
    }
    AppStorage.setOrCreate(KEY_STATE, init)
    return init
  }

  static setState(s: DoorLockStateRecord): void {
    AppStorage.setOrCreate(KEY_STATE, s)
  }

  // ----------------- 日志读写 -----------------

  static getLogs(): UnlockLogEntry[] {
    const stored = AppStorage.get<UnlockLogEntry[]>(KEY_LOGS)
    if (stored && Array.isArray(stored)) return stored
    return []
  }

  static appendLog(entry: UnlockLogEntry): UnlockLogEntry[] {
    const logs = DoorLockService.getLogs()
    logs.unshift(entry)  // 最新在前
    if (logs.length > MAX_LOGS) logs.length = MAX_LOGS
    AppStorage.setOrCreate(KEY_LOGS, logs)
    return logs
  }

  static clearLogs(): void {
    AppStorage.setOrCreate(KEY_LOGS, [])
  }

  // ----------------- 业务动作 -----------------

  /**
   * 远程解锁：模拟延时 UNLOCK_DELAY_MS 毫秒后切换状态。
   * 流程：写"开始"日志 → 延时 → 切状态 → 写"成功"日志 → 发跨域事件。
   */
  static async unlock(operator: string, source: string = 'remote'): Promise<DoorLockStateRecord> {
    const startTs = Date.now()

    // 1) 立即写一条"进行中"日志
    const startEntry: UnlockLogEntry = {
      id: DoorLockService.genId('lock', 'unlock-start', source),
      doorlockId: DOORLOCK_ID,
      operator: operator,
      result: 'cancelled' as UnlockResult,  // 占位，结束时覆写
      timestamp: startTs,
      source: source
    }
    DoorLockService.appendLog(startEntry)

    // 2) 模拟网络延时
    await new Promise<void>((resolve) => setTimeout(resolve, UNLOCK_DELAY_MS))

    // 3) 切换状态
    const prev = DoorLockService.getState()
    const next: DoorLockStateRecord = {
      id: prev.id,
      name: prev.name,
      state: 'unlocked' as DoorLockState,
      battery: prev.battery,
      updatedAt: Date.now()
    }
    DoorLockService.setState(next)

    // 4) 写成功日志（覆写"开始"条目）
    const endEntry: UnlockLogEntry = {
      id: DoorLockService.genId('lock', 'unlock-ok', source),
      doorlockId: DOORLOCK_ID,
      operator: operator,
      result: 'success' as UnlockResult,
      timestamp: Date.now(),
      source: source
    }
    DoorLockService.appendLog(endEntry)

    // 5) 发跨域事件（被 GatewayService 订阅后触发灯组/温控等联动）
    const payload = new EventPayload()
    payload.doorlockId = DOORLOCK_ID
    payload.state = 'unlocked'
    payload.battery = next.battery
    payload.operator = operator
    payload.result = 'success'
    payload.source = source
    const evt: GatewayEvent = {
      source: 'lock',
      type: 'unlocked',
      timestamp: Date.now(),
      payload: payload
    }
    GatewayBus.publish(evt)

    return next
  }

  /**
   * 上锁：本地同步操作，无延时。写日志并发事件。
   */
  static lock(operator: string, source: string = 'manual'): DoorLockStateRecord {
    const prev = DoorLockService.getState()
    const next: DoorLockStateRecord = {
      id: prev.id,
      name: prev.name,
      state: 'locked' as DoorLockState,
      battery: prev.battery,
      updatedAt: Date.now()
    }
    DoorLockService.setState(next)

    const entry: UnlockLogEntry = {
      id: DoorLockService.genId('lock', 'lock', source),
      doorlockId: DOORLOCK_ID,
      operator: operator,
      result: 'success' as UnlockResult,
      timestamp: Date.now(),
      source: source
    }
    DoorLockService.appendLog(entry)

    const payload = new EventPayload()
    payload.doorlockId = DOORLOCK_ID
    payload.state = 'locked'
    payload.battery = next.battery
    payload.operator = operator
    payload.result = 'success'
    payload.source = source
    const evt: GatewayEvent = {
      source: 'lock',
      type: 'locked',
      timestamp: Date.now(),
      payload: payload
    }
    GatewayBus.publish(evt)

    return next
  }

  // ----------------- 工具 -----------------

  private static genId(...parts: string[]): string {
    return parts.join('·') + '·' + Date.now()
  }
}
