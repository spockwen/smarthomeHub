/**
 * GatewayBus
 * ------------------------------------------------------------
 * 轻量级进程内事件总线：为门锁/温控/规则引擎提供一个解耦的事件通道。
 *
 * 职责：
 *   1. DoorLockService / ClimateService 等业务 Service 调用 publish() 发出 GatewayEvent
 *   2. GatewayService 在 init() 时 subscribe() 监听这些事件，运行规则引擎并派发
 *
 * 设计原则：
 *   - 静态方法 + AppStorage 不依赖（纯模块内 in-memory 状态）
 *   - 极简 API：publish / subscribe / clear
 *   - 单订阅者：只允许一个 GatewayService 注册（避免事件被多次派发）
 *
 * 注意：此模块刻意保持独立，避免与 GatewayService 形成循环导入。
 */

import { GatewayEvent } from '../models/GatewayModel'

type GatewayEventHandler = (event: GatewayEvent) => void

export class GatewayBus {
  private static handler: GatewayEventHandler | null = null

  /**
   * 由 GatewayService.init() 调用，注册唯一的事件处理函数。
   * 重复注册将覆盖旧的 handler（与"单订阅者"约定一致）。
   */
  static subscribe(handler: GatewayEventHandler): void {
    GatewayBus.handler = handler
  }

  /**
   * 解除订阅（如页面销毁时）。
   */
  static unsubscribe(): void {
    GatewayBus.handler = null
  }

  /**
   * 业务侧发布事件。无订阅者时静默丢弃。
   */
  static publish(event: GatewayEvent): void {
    if (GatewayBus.handler) {
      try {
        GatewayBus.handler(event)
      } catch (e) {
        console.error('[GatewayBus] handler error:', JSON.stringify(e))
      }
    }
  }
}
