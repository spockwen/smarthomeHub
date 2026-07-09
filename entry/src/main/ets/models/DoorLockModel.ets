/**
 * 门锁中心 - 领域模型
 *
 * 涵盖：
 *   - DoorLockState : 门锁实时状态（开 / 关 / 告警）
 *   - UnlockLogEntry: 开锁日志条目（最近 N 条）
 *   - LockEventPayload : 锁事件 payload，发布到 GatewayEventBus 时使用
 */

// ==================== 门锁状态 ====================
/**
 * 门锁状态：
 *  - locked  : 已上锁
 *  - unlocked: 已开锁
 *  - jammed  : 锁体异常
 */
export type DoorLockState = 'locked' | 'unlocked' | 'jammed'

/**
 * 电池电量 0-100，低于 20 进入低电告警。
 */
export interface DoorLockStateRecord {
  id: string                  // 'doorlock_front'
  name: string                // '前门门锁'
  state: DoorLockState
  battery: number             // 0-100
  updatedAt: number           // ms
}

// ==================== 开锁日志 ====================
export type UnlockResult = 'success' | 'failed' | 'cancelled'

export interface UnlockLogEntry {
  id: string
  doorlockId: string
  operator: string            // '家庭成员' / '远程用户'
  result: UnlockResult
  timestamp: number
  /** 触发来源：'remote' | 'rule' | 'manual' */
  source: string
}

// ==================== 事件 payload ====================
/**
 * DoorLockService → GatewayService 发布事件时使用的 payload。
 *  - 与 GatewayEvent.payload 类型保持一致（string/number/boolean）。
 */
export interface LockEventPayload {
  doorlockId: string
  state: DoorLockState
  battery: number
  operator: string
  result: UnlockResult
  source: string
}
