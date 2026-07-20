// ============================================================
// 设备注册中心 - DeviceRegistry.ets
//
// 职责：
//   1. 提供统一的设备注册/注销/查询 API
//   2. 隔离设备元数据与业务逻辑，解耦 DeviceStateService
//   3. 支持运行时动态注册（用于模拟器/新品牌灵活接入）
//   4. 协议适配器接口，新品牌设备只需实现 IDeviceProtocol
//
// 使用场景：
//   - 在 EntryAbility 的 onCreate() 中批量注册设备
//   - Node.js 模拟器上报新设备时，通过 MQTT 消息动态注册
//   - 第三方品牌接入时，只需实现 IDeviceProtocol 接口
//
// ============================================================
//
// 【接入指南 — 新品牌设备接入步骤】
//
//   step 1: 实现 IDeviceProtocol 接口
//   ─────────────────────────────────
//   class GreeACProtocol implements IDeviceProtocol {
//     brand = 'gree'
//     parseState(raw: string): Record<string, any> {
//       // 解析格力空调私有协议 → 统一状态对象
//       return { power: true, temp: 26, mode: 'cool' }
//     }
//     buildCommand(deviceId: string, action: string, params?: any): string {
//       // 将统一动作 → 格力私有指令
//       return `${deviceId}:set_temp(${params})`
//     }
//   }
//
//   step 2: 注册设备元数据 + 协议适配器
//   ──────────────────────────────────────
//   import { deviceRegistry } from '../service/DeviceRegistry'
//
//   deviceRegistry.register({
//     meta: {
//       name: '格力空调',
//       icon: '❄️',
//       room: '主卧',
//       hasSwitch: true,
//       hasSlider: true,
//       sliderKey: 'acTemp',
//       sliderMin: 16,
//       sliderMax: 30,
//       sliderUnit: '℃'
//     },
//     protocol: new GreeACProtocol()
//   })
//
//   step 3: MQTT 主题自动映射
//   ──────────────────────────
//   deviceRegistry.getDeviceId('格力空调')
//   // → 返回 'gree_ac_bedroom' （自动生成或自定义）
//
// ============================================================
//
// 【架构说明】
//   本服务位于 DeviceStateService 的上层，MqttService 的下层：
//   UI 层 → DeviceRegistry（查设备）→ DeviceStateService（读状态）
//   MqttService（收消息）→ DeviceRegistry（查协议）→ 解析状态
//
// ============================================================

import { DeviceMeta } from '../model/DeviceModel'

// =================================================================
// 1. 协议适配器接口
// =================================================================

/**
 * 设备协议适配器接口。
 * 每个品牌/协议族实现一个 Adapter，将私有协议翻译为系统统一格式。
 *
 * 设计理由：
 * - 开闭原则：新增品牌只需新增 Adapter 类，无需修改现有代码
 * - 单一职责：协议解析逻辑与业务逻辑分离
 * - 可测试性：每个 Adapter 可独立单元测试
 */
export interface IDeviceProtocol {
  /** 品牌标识，如 'gree'、'midea'、'haier' */
  readonly brand: string

  /**
   * 将设备上报的原始数据解析为统一状态对象
   * @param raw - MQTT 收到的原始 payload（JSON 字符串）
   * @returns 统一格式的状态键值对
   */
  parseState(raw: string): Record<string, any>

  /**
   * 将统一格式的控制指令转换为设备私有指令
   * @param deviceId - 设备标识
   * @param action   - 动作名称（'on' | 'off' | 'set_temp' | 'set_mode' 等）
   * @param params   - 动作参数（可选）
   * @returns 设备私有协议的指令字符串
   */
  buildCommand(deviceId: string, action: string, params?: any): string
}

// =================================================================
// 2. 注册项类型
// =================================================================

/** 设备注册信息 */
export interface DeviceRegistration {
  /** 设备元数据（显示用） */
  meta: DeviceMeta
  /** 协议适配器（可选，无则使用默认 JSON 协议） */
  protocol?: IDeviceProtocol
  /** 设备在 MQTT 主题中的唯一标识（默认自动生成） */
  deviceId?: string
  /** 注册时间戳 */
  registeredAt?: number
  /** 是否为模拟器注册的虚拟设备 */
  isVirtual?: boolean
}

// =================================================================
// 3. 注册中心实现
// =================================================================

class DeviceRegistry {
  /** 内部存储：name → Registration */
  private entries: Map<string, DeviceRegistration> = new Map()

  // ---------------------------------------------------------------
  // 3a. 注册 / 注销
  // ---------------------------------------------------------------

  /**
   * 注册一个设备到系统中。
   * 如果同名设备已存在，会覆盖（打印警告）。
   *
   * @param registration - 设备注册信息
   * @returns 是否为新注册（true=新增，false=覆盖）
   *
   * @example
   * deviceRegistry.register({
   *   meta: { name: '客厅灯', icon: '💡', room: '客厅', hasSwitch: true },
   *   deviceId: 'living_room_light'
   * })
   */
  register(registration: DeviceRegistration): boolean {
    const name = registration.meta.name
    const isNew = !this.entries.has(name)

    if (!isNew) {
      console.warn(`[DeviceRegistry] 设备 "${name}" 已存在，将被覆盖`)
    }

    // 补充默认值
    const entry: DeviceRegistration = {
      ...registration,
      deviceId: registration.deviceId ?? this.generateDeviceId(name),
      registeredAt: registration.registeredAt ?? Date.now(),
      isVirtual: registration.isVirtual ?? false
    }

    this.entries.set(name, entry)
    console.info(`[DeviceRegistry] 设备 "${name}" 注册成功 ` +
      `(deviceId=${entry.deviceId}, isVirtual=${entry.isVirtual})`)
    return isNew
  }

  /**
   * 批量注册设备（用于初始化时加载全部设备列表）。
   *
   * @param registrations - 设备注册信息数组
   * @returns 成功注册的数量
   *
   * @example
   * deviceRegistry.registerAll([...INIT_DEVICES])
   */
  registerAll(registrations: DeviceRegistration[]): number {
    let count = 0
    for (const reg of registrations) {
      if (this.register(reg)) {
        count++
      }
    }
    console.info(`[DeviceRegistry] 批量注册完成：${count} 个新设备`)
    return count
  }

  /**
   * 注销指定设备。
   *
   * @param name - 设备名称
   * @returns 是否成功注销（false 表示设备不存在）
   */
  unregister(name: string): boolean {
    const existed = this.entries.delete(name)
    if (existed) {
      console.info(`[DeviceRegistry] 设备 "${name}" 已注销`)
    } else {
      console.warn(`[DeviceRegistry] 设备 "${name}" 不存在，无法注销`)
    }
    return existed
  }

  /**
   * 清空所有注册设备（慎用）。
   */
  clear(): void {
    const count = this.entries.size
    this.entries.clear()
    console.warn(`[DeviceRegistry] 已清空所有 ${count} 个设备注册`)
  }

  // ---------------------------------------------------------------
  // 3b. 查询
  // ---------------------------------------------------------------

  /**
   * 根据名称查询设备元数据。
   *
   * @param name - 设备名称
   * @returns 设备元数据，不存在返回 undefined
   */
  getMeta(name: string): DeviceMeta | undefined {
    return this.entries.get(name)?.meta
  }

  /**
   * 根据名称查询完整的注册信息。
   *
   * @param name - 设备名称
   * @returns 完整注册信息，不存在返回 undefined
   */
  getRegistration(name: string): DeviceRegistration | undefined {
    return this.entries.get(name)
  }

  /**
   * 获取设备对应的 MQTT deviceId。
   *
   * @param name - 设备名称
   * @returns MQTT 标识，不存在返回 undefined
   */
  getDeviceId(name: string): string | undefined {
    return this.entries.get(name)?.deviceId
  }

  /**
   * 获取设备的协议适配器。
   *
   * @param name - 设备名称
   * @returns 协议适配器（可能为 undefined，此时使用默认 JSON 协议）
   */
  getProtocol(name: string): IDeviceProtocol | undefined {
    return this.entries.get(name)?.protocol
  }

  /**
   * 获取全量设备列表（用于 UI 渲染）。
   *
   * @returns 所有已注册设备的元数据数组
   */
  getAllDevices(): DeviceMeta[] {
    const result: DeviceMeta[] = []
    this.entries.forEach(entry => result.push(entry.meta))
    return result
  }

  /**
   * 按房间筛选设备。
   *
   * @param room - 房间名称（传 '全部' 返回所有设备）
   * @returns 该房间内的设备元数据数组
   */
  getDevicesByRoom(room: string): DeviceMeta[] {
    if (room === '全部') {
      return this.getAllDevices()
    }
    const result: DeviceMeta[] = []
    this.entries.forEach(entry => {
      if (entry.meta.room === room) {
        result.push(entry.meta)
      }
    })
    return result
  }

  /**
   * 检查设备是否已注册。
   *
   * @param name - 设备名称
   * @returns 是否存在
   */
  exists(name: string): boolean {
    return this.entries.has(name)
  }

  /**
   * 获取已注册设备的数量。
   */
  get count(): number {
    return this.entries.size
  }

  /**
   * 获取所有注册信息（用于序列化/持久化）。
   */
  snapshot(): DeviceRegistration[] {
    const result: DeviceRegistration[] = []
    this.entries.forEach(entry => result.push(entry))
    return result
  }

  // ---------------------------------------------------------------
  // 3c. 内部工具
  // ---------------------------------------------------------------

  /**
   * 根据设备名自动生成 deviceId。
   * 规则：小写 + 下划线，去除特殊字符。
   *
   * @param name - 设备名称
   * @returns 生成的 deviceId
   */
  private generateDeviceId(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9\u4e00-\u9fa5]/g, '_')
      .replace(/_+/g, '_')
      .replace(/^_|_$/g, '')
  }
}

// =================================================================
// 4. 全局单例
// =================================================================

/**
 * 全局唯一的设备注册中心实例。
 * 推荐在 EntryAbility 的 onCreate() 中完成所有初始化注册。
 *
 * @example
 * // EntryAbility.ets
 * import { deviceRegistry, DeviceRegistration } from '../service/DeviceRegistry'
 *
 * const INIT_DEVICES: DeviceRegistration[] = [
 *   { meta: { name: '客厅灯', icon: '💡', room: '客厅', hasSwitch: true } },
 *   { meta: { name: '空调', icon: '❄️', room: '客厅', hasSwitch: true, hasSlider: true, sliderKey: 'acTemp', sliderMin: 16, sliderMax: 30, sliderUnit: '℃' } }
 * ]
 *
 * export default class EntryAbility extends UIAbility {
 *   onCreate() {
 *     deviceRegistry.registerAll(INIT_DEVICES)
 *     // ...
 *   }
 * }
 */
export const deviceRegistry = new DeviceRegistry()
