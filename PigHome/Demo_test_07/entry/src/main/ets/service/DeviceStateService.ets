// ============================================================
// 设备状态共享服务 - DeviceStateService.ets
//
// 职责：
//   1. 统一管理所有智能设备状态（AppStorage 全局共享）
//   2. Preferences 本地持久化（重启不丢失）
//   3. 房间筛选 / 在线设备统计
//   4. AI 聊天记录持久化
// ============================================================

import dataPreferences from '@ohos.data.preferences'
import { ChatMessage } from '../model/DeviceModel'

// =================================================================
//  1. 元数据定义
// =================================================================

/** 设备基础信息 */
export interface DeviceMeta {
  name: string          // 设备名（唯一标识）
  icon: string          // 显示图标
  room: string          // 所属房间
  hasSwitch: boolean    // 是否有开关
  hasSlider: boolean    // 是否有拖动条
  sliderKey?: string    // 拖动条对应的 AppStorage key
  sliderMin?: number
  sliderMax?: number
  sliderUnit?: string   // 单位字符，如"℃"、"%"、""
}

const ALL_DEVICES: DeviceMeta[] = [
  { name: '客厅主灯',   icon: '💡', room: '客厅', hasSwitch: true, hasSlider: false },
  { name: '书房灯',     icon: '💡', room: '书房', hasSwitch: true, hasSlider: true,
    sliderKey: 'studyLightLevel', sliderMin: 0, sliderMax: 100, sliderUnit: '%' },
  { name: '油烟机',     icon: '🍳', room: '厨房', hasSwitch: true, hasSlider: false },
  { name: '空气净化器', icon: '💨', room: '客厅', hasSwitch: true, hasSlider: false },
  { name: '空调',       icon: '❄️', room: '客厅', hasSwitch: true, hasSlider: true,
    sliderKey: 'acTemp', sliderMin: 16, sliderMax: 30, sliderUnit: '℃' },
  { name: '电动窗帘',   icon: '🪟', room: '主卧', hasSwitch: true, hasSlider: true,
    sliderKey: 'curtainLevel', sliderMin: 0, sliderMax: 100, sliderUnit: '%' },
  { name: '投影仪',     icon: '🎥', room: '客厅', hasSwitch: true, hasSlider: false },
  { name: '智能门锁',   icon: '🔒', room: '客厅', hasSwitch: true, hasSlider: false },
]

export const ROOMS: string[] = ['全部', '客厅', '主卧', '书房', '厨房']

/** 通过设备名获取元数据 */
export function getDeviceMeta(name: string): DeviceMeta | undefined {
  for (let i = 0; i < ALL_DEVICES.length; i++) {
    if (ALL_DEVICES[i].name === name) {
      return ALL_DEVICES[i]
    }
  }
  return undefined
}

/** 筛选某房间的设备列表 */
export function getDevicesByRoom(room: string): DeviceMeta[] {
  if (room === '全部') {
    return ALL_DEVICES
  }
  const result: DeviceMeta[] = []
  for (let i = 0; i < ALL_DEVICES.length; i++) {
    if (ALL_DEVICES[i].room === room) {
      result.push(ALL_DEVICES[i])
    }
  }
  return result
}

/** 统计当前在线的设备数量 */
export function getOnlineDeviceCount(): number {
  let count = 0
  for (let i = 0; i < ALL_DEVICES.length; i++) {
    if (isDeviceOn(ALL_DEVICES[i].name)) {
      count++
    }
  }
  return count
}

// =================================================================
//  2. AppStorage Key 定义
// =================================================================

interface KeysType {
  LIGHT_ON: string
  STUDY_LIGHT_ON: string
  STUDY_LIGHT_LEVEL: string
  RANGE_HOOD_ON: string
  PURIFIER_ON: string
  AC_ON: string
  AC_TEMP: string
  CURTAIN_ON: string
  CURTAIN_LEVEL: string
  PROJECTOR_ON: string
  DOOR_LOCKED: string
}

export const KEYS: KeysType = {
  LIGHT_ON: 'isLightOn',
  STUDY_LIGHT_ON: 'isStudyLightOn',
  STUDY_LIGHT_LEVEL: 'studyLightLevel',
  RANGE_HOOD_ON: 'isRangeHoodOn',
  PURIFIER_ON: 'isPurifierOn',
  AC_ON: 'isACOn',
  AC_TEMP: 'acTemp',
  CURTAIN_ON: 'isCurtainOn',
  CURTAIN_LEVEL: 'curtainLevel',
  PROJECTOR_ON: 'isProjectorOn',
  DOOR_LOCKED: 'isDoorLocked'
}

/** 所有 Key 列表（方便遍历） */
const KEY_LIST: string[] = [
  KEYS.LIGHT_ON, KEYS.STUDY_LIGHT_ON, KEYS.STUDY_LIGHT_LEVEL,
  KEYS.RANGE_HOOD_ON, KEYS.PURIFIER_ON,
  KEYS.AC_ON, KEYS.AC_TEMP,
  KEYS.CURTAIN_ON, KEYS.CURTAIN_LEVEL,
  KEYS.PROJECTOR_ON, KEYS.DOOR_LOCKED
]

/** 设备名 → 关联的 AppStorage Key 列表 */
const DEVICE_KEYS: Record<string, string[]> = {
  '客厅主灯':   [KEYS.LIGHT_ON],
  '书房灯':     [KEYS.STUDY_LIGHT_ON, KEYS.STUDY_LIGHT_LEVEL],
  '油烟机':     [KEYS.RANGE_HOOD_ON],
  '空气净化器': [KEYS.PURIFIER_ON],
  '空调':       [KEYS.AC_ON, KEYS.AC_TEMP],
  '电动窗帘':   [KEYS.CURTAIN_ON, KEYS.CURTAIN_LEVEL],
  '投影仪':     [KEYS.PROJECTOR_ON],
  '智能门锁':   [KEYS.DOOR_LOCKED]
}

// =================================================================
//  3. Preferences 持久化
// =================================================================

const PREFS_NAME = 'smart_home_store'
const KEY_DEVICE_STATES = 'device_states'
const KEY_CHAT_HISTORY = 'chat_history'

let prefsInstance: dataPreferences.Preferences | null = null
let saveTimer: number | null = null

/** 初始化 Preferences（应用启动时调用一次） */
export async function initDeviceState(context: Context): Promise<void> {
  prefsInstance = await dataPreferences.getPreferences(context, PREFS_NAME)
  await loadDeviceStates()
}

/** 从 Preferences 读取并恢复设备状态 */
async function loadDeviceStates(): Promise<void> {
  if (prefsInstance === null) return

  // 默认值（逐个赋值，避免 computed property names）
  const defIsLightOn = true
  const defStudyOn = true
  const defStudyLevel = 100
  const defHoodOn = true
  const defPurifierOn = true
  const defACOn = true
  const defACTemp = 24
  const defCurtainOn = true
  const defCurtainLevel = 100
  const defProjectorOn = false
  const defDoorLocked = true

  // ---- 尝试从 Preferences 恢复已保存状态 ----
  const savedVal: string = (await prefsInstance.get(KEY_DEVICE_STATES, '')) as string
  if (savedVal.length > 0) {
    try {
      const saved: Record<string, Object> = JSON.parse(savedVal) as Record<string, Object>
      // 逐一读取 saved 中的值，安全 fallback 到默认值
      // 注：ArkTS 不支持 in 运算符和动态属性名，使用 typeof 逐一判断
      AppStorage.SetOrCreate(KEYS.LIGHT_ON,
        (typeof (saved[KEYS.LIGHT_ON] as Object) === 'boolean') ? (saved[KEYS.LIGHT_ON] as boolean) : defIsLightOn)
      AppStorage.SetOrCreate(KEYS.STUDY_LIGHT_ON,
        (typeof (saved[KEYS.STUDY_LIGHT_ON] as Object) === 'boolean') ? (saved[KEYS.STUDY_LIGHT_ON] as boolean) : defStudyOn)
      AppStorage.SetOrCreate(KEYS.STUDY_LIGHT_LEVEL,
        (typeof (saved[KEYS.STUDY_LIGHT_LEVEL] as Object) === 'number') ? (saved[KEYS.STUDY_LIGHT_LEVEL] as number) : defStudyLevel)
      AppStorage.SetOrCreate(KEYS.RANGE_HOOD_ON,
        (typeof (saved[KEYS.RANGE_HOOD_ON] as Object) === 'boolean') ? (saved[KEYS.RANGE_HOOD_ON] as boolean) : defHoodOn)
      AppStorage.SetOrCreate(KEYS.PURIFIER_ON,
        (typeof (saved[KEYS.PURIFIER_ON] as Object) === 'boolean') ? (saved[KEYS.PURIFIER_ON] as boolean) : defPurifierOn)
      AppStorage.SetOrCreate(KEYS.AC_ON,
        (typeof (saved[KEYS.AC_ON] as Object) === 'boolean') ? (saved[KEYS.AC_ON] as boolean) : defACOn)
      AppStorage.SetOrCreate(KEYS.AC_TEMP,
        (typeof (saved[KEYS.AC_TEMP] as Object) === 'number') ? (saved[KEYS.AC_TEMP] as number) : defACTemp)
      AppStorage.SetOrCreate(KEYS.CURTAIN_ON,
        (typeof (saved[KEYS.CURTAIN_ON] as Object) === 'boolean') ? (saved[KEYS.CURTAIN_ON] as boolean) : defCurtainOn)
      AppStorage.SetOrCreate(KEYS.CURTAIN_LEVEL,
        (typeof (saved[KEYS.CURTAIN_LEVEL] as Object) === 'number') ? (saved[KEYS.CURTAIN_LEVEL] as number) : defCurtainLevel)
      AppStorage.SetOrCreate(KEYS.PROJECTOR_ON,
        (typeof (saved[KEYS.PROJECTOR_ON] as Object) === 'boolean') ? (saved[KEYS.PROJECTOR_ON] as boolean) : defProjectorOn)
      AppStorage.SetOrCreate(KEYS.DOOR_LOCKED,
        (typeof (saved[KEYS.DOOR_LOCKED] as Object) === 'boolean') ? (saved[KEYS.DOOR_LOCKED] as boolean) : defDoorLocked)
    } catch (_err) {
      // 解析失败 → 用默认值
      setDefaultStates()
    }
  } else {
    setDefaultStates()
  }
}

/** 用默认值初始化所有设备状态 */
function setDefaultStates(): void {
  AppStorage.SetOrCreate(KEYS.LIGHT_ON, true)
  AppStorage.SetOrCreate(KEYS.STUDY_LIGHT_ON, true)
  AppStorage.SetOrCreate(KEYS.STUDY_LIGHT_LEVEL, 100)
  AppStorage.SetOrCreate(KEYS.RANGE_HOOD_ON, true)
  AppStorage.SetOrCreate(KEYS.PURIFIER_ON, true)
  AppStorage.SetOrCreate(KEYS.AC_ON, true)
  AppStorage.SetOrCreate(KEYS.AC_TEMP, 24)
  AppStorage.SetOrCreate(KEYS.CURTAIN_ON, true)
  AppStorage.SetOrCreate(KEYS.CURTAIN_LEVEL, 100)
  AppStorage.SetOrCreate(KEYS.PROJECTOR_ON, false)
  AppStorage.SetOrCreate(KEYS.DOOR_LOCKED, true)
}

/** 将所有 AppStorage 设备状态持久化到 Preferences（防抖 300ms） */
function markDirty(): void {
  if (saveTimer !== null) {
    clearTimeout(saveTimer)
  }
  saveTimer = setTimeout(async () => {
    await flushDeviceStates()
  }, 300)
}

/** 立即将当前设备状态写入 Preferences */
export async function flushDeviceStates(): Promise<void> {
  if (prefsInstance === null) return

  // 手动拼接 JSON，避免使用 object literals 的复杂问题
  const valIsLightOn = AppStorage.Get<boolean>(KEYS.LIGHT_ON) ?? true
  const valStudyOn = AppStorage.Get<boolean>(KEYS.STUDY_LIGHT_ON) ?? true
  const valStudyLevel = AppStorage.Get<number>(KEYS.STUDY_LIGHT_LEVEL) ?? 100
  const valHoodOn = AppStorage.Get<boolean>(KEYS.RANGE_HOOD_ON) ?? true
  const valPurifierOn = AppStorage.Get<boolean>(KEYS.PURIFIER_ON) ?? true
  const valACOn = AppStorage.Get<boolean>(KEYS.AC_ON) ?? true
  const valACTemp = AppStorage.Get<number>(KEYS.AC_TEMP) ?? 24
  const valCurtainOn = AppStorage.Get<boolean>(KEYS.CURTAIN_ON) ?? true
  const valCurtainLevel = AppStorage.Get<number>(KEYS.CURTAIN_LEVEL) ?? 100
  const valProjectorOn = AppStorage.Get<boolean>(KEYS.PROJECTOR_ON) ?? false
  const valDoorLocked = AppStorage.Get<boolean>(KEYS.DOOR_LOCKED) ?? true

  const jsonStr = '{'
    + '"' + KEYS.LIGHT_ON + '":' + valIsLightOn + ','
    + '"' + KEYS.STUDY_LIGHT_ON + '":' + valStudyOn + ','
    + '"' + KEYS.STUDY_LIGHT_LEVEL + '":' + valStudyLevel + ','
    + '"' + KEYS.RANGE_HOOD_ON + '":' + valHoodOn + ','
    + '"' + KEYS.PURIFIER_ON + '":' + valPurifierOn + ','
    + '"' + KEYS.AC_ON + '":' + valACOn + ','
    + '"' + KEYS.AC_TEMP + '":' + valACTemp + ','
    + '"' + KEYS.CURTAIN_ON + '":' + valCurtainOn + ','
    + '"' + KEYS.CURTAIN_LEVEL + '":' + valCurtainLevel + ','
    + '"' + KEYS.PROJECTOR_ON + '":' + valProjectorOn + ','
    + '"' + KEYS.DOOR_LOCKED + '":' + valDoorLocked
    + '}'

  await prefsInstance.put(KEY_DEVICE_STATES, jsonStr)
  await prefsInstance.flush()
}

// =================================================================
//  4. 设备状态读取
// =================================================================

/** 获取设备是否开启 */
export function isDeviceOn(name: string): boolean {
  const keys = DEVICE_KEYS[name]
  if (!keys || keys.length === 0) return false
  if (name === '智能门锁') {
    return !AppStorage.Get<boolean>(KEYS.DOOR_LOCKED)!
  }
  return AppStorage.Get<boolean>(keys[0]) ?? false
}

/** 获取设备拖动条数值 */
export function getDeviceSliderValue(name: string): number {
  const meta = getDeviceMeta(name)
  if (meta === undefined || meta.sliderKey === undefined) return 0
  return AppStorage.Get<number>(meta.sliderKey) ?? 0
}

/** 获取设备的概要状态文本 */
export function getDeviceStatusText(name: string): string {
  if (name === '客厅主灯') {
    return AppStorage.Get<boolean>(KEYS.LIGHT_ON) ? '100%' : '已关闭'
  }
  if (name === '书房灯') {
    return AppStorage.Get<boolean>(KEYS.STUDY_LIGHT_ON)
      ? AppStorage.Get<number>(KEYS.STUDY_LIGHT_LEVEL) + '%'
      : '已关闭'
  }
  if (name === '油烟机') {
    return AppStorage.Get<boolean>(KEYS.RANGE_HOOD_ON) ? '运行中' : '已关闭'
  }
  if (name === '空气净化器') {
    return AppStorage.Get<boolean>(KEYS.PURIFIER_ON) ? 'AQI 12 优' : '已关闭'
  }
  if (name === '空调') {
    return AppStorage.Get<boolean>(KEYS.AC_ON)
      ? AppStorage.Get<number>(KEYS.AC_TEMP) + '℃ 制冷'
      : '已关闭'
  }
  if (name === '电动窗帘') {
    return AppStorage.Get<boolean>(KEYS.CURTAIN_ON)
      ? AppStorage.Get<number>(KEYS.CURTAIN_LEVEL) + '%'
      : '已关闭'
  }
  if (name === '投影仪') {
    return AppStorage.Get<boolean>(KEYS.PROJECTOR_ON) ? '运行中' : '已关闭'
  }
  if (name === '智能门锁') {
    return AppStorage.Get<boolean>(KEYS.DOOR_LOCKED) ? '已锁定' : '已解锁'
  }
  return ''
}

// =================================================================
//  5. 设备控制（开关 / 调节 / 场景）
// =================================================================

export interface AdjustResult {
  message: string
  success: boolean
}

/** 切换设备开关 */
export function toggleDevice(name: string): string {
  if (name === '客厅主灯') {
    const newVal = !AppStorage.Get<boolean>(KEYS.LIGHT_ON)
    AppStorage.Set(KEYS.LIGHT_ON, newVal)
    markDirty()
    return newVal ? '客厅主灯已打开 💡' : '客厅主灯已关闭'
  }
  if (name === '书房灯') {
    const newVal = !AppStorage.Get<boolean>(KEYS.STUDY_LIGHT_ON)
    AppStorage.Set(KEYS.STUDY_LIGHT_ON, newVal)
    markDirty()
    return newVal ? '书房灯已打开 💡' : '书房灯已关闭'
  }
  if (name === '油烟机') {
    const newVal = !AppStorage.Get<boolean>(KEYS.RANGE_HOOD_ON)
    AppStorage.Set(KEYS.RANGE_HOOD_ON, newVal)
    markDirty()
    return newVal ? '油烟机已开启 🍳' : '油烟机已关闭'
  }
  if (name === '空气净化器') {
    const newVal = !AppStorage.Get<boolean>(KEYS.PURIFIER_ON)
    AppStorage.Set(KEYS.PURIFIER_ON, newVal)
    markDirty()
    return newVal ? '空气净化器已开启 💨' : '空气净化器已关闭'
  }
  if (name === '空调') {
    const newVal = !AppStorage.Get<boolean>(KEYS.AC_ON)
    AppStorage.Set(KEYS.AC_ON, newVal)
    markDirty()
    return newVal ? '空调已开启 ❄️' : '空调已关闭'
  }
  if (name === '电动窗帘') {
    const newVal = !AppStorage.Get<boolean>(KEYS.CURTAIN_ON)
    AppStorage.Set(KEYS.CURTAIN_ON, newVal)
    markDirty()
    return newVal ? '电动窗帘已打开 🪟' : '电动窗帘已关闭'
  }
  if (name === '投影仪') {
    const newVal = !AppStorage.Get<boolean>(KEYS.PROJECTOR_ON)
    AppStorage.Set(KEYS.PROJECTOR_ON, newVal)
    markDirty()
    return newVal ? '投影仪已开启 🎥' : '投影仪已关闭'
  }
  if (name === '智能门锁') {
    const newVal = !AppStorage.Get<boolean>(KEYS.DOOR_LOCKED)
    AppStorage.Set(KEYS.DOOR_LOCKED, newVal)
    markDirty()
    return newVal ? '门锁已锁定 🔒' : '门锁已解锁 🔓'
  }
  if (name === '灯' || name === '所有灯') {
    return toggleAllLights()
  }
  return '未找到设备"' + name + '"'
}

/** 批量开灯 */
export function toggleAllLights(): string {
  AppStorage.Set(KEYS.LIGHT_ON, true)
  AppStorage.Set(KEYS.STUDY_LIGHT_ON, true)
  markDirty()
  return '全部灯光已打开 💡'
}

/** 调节设备参数 */
export function adjustDevice(name: string, value: number): AdjustResult {
  if (name === '空调' || name === '空调温度') {
    if (value < 16 || value > 30) {
      return { message: '空调温度请在16~30℃之间调节', success: false }
    }
    AppStorage.Set(KEYS.AC_TEMP, value)
    AppStorage.Set(KEYS.AC_ON, true)
    markDirty()
    return { message: '空调已调至' + value + '℃ ❄️', success: true }
  }
  if (name === '书房灯' || name === '书房灯亮度') {
    if (value < 0 || value > 100) {
      return { message: '亮度值请在0~100之间调节', success: false }
    }
    AppStorage.Set(KEYS.STUDY_LIGHT_LEVEL, value)
    AppStorage.Set(KEYS.STUDY_LIGHT_ON, value > 0)
    markDirty()
    return { message: '书房灯亮度已调至' + value + '% 💡', success: true }
  }
  if (name === '电动窗帘' || name === '窗帘' || name === '窗帘开合度') {
    if (value < 0 || value > 100) {
      return { message: '开合度请在0~100之间调节', success: false }
    }
    AppStorage.Set(KEYS.CURTAIN_LEVEL, value)
    AppStorage.Set(KEYS.CURTAIN_ON, value > 0)
    markDirty()
    return { message: '窗帘开合度已调至' + value + '% 🪟', success: true }
  }
  return { message: '暂不支持调节"' + name + '"', success: false }
}

/** 场景模式 */
export function executeScene(name: string): string {
  if (name === '离家模式') {
    AppStorage.Set(KEYS.LIGHT_ON, false)
    AppStorage.Set(KEYS.STUDY_LIGHT_ON, false)
    AppStorage.Set(KEYS.STUDY_LIGHT_LEVEL, 0)
    AppStorage.Set(KEYS.AC_ON, false)
    AppStorage.Set(KEYS.RANGE_HOOD_ON, false)
    AppStorage.Set(KEYS.PURIFIER_ON, false)
    AppStorage.Set(KEYS.CURTAIN_ON, false)
    AppStorage.Set(KEYS.CURTAIN_LEVEL, 0)
    AppStorage.Set(KEYS.PROJECTOR_ON, false)
    AppStorage.Set(KEYS.DOOR_LOCKED, true)
    markDirty()
    return '离家模式已启动 🏠\n全屋灯光、空调、电器已关闭，门锁已锁定 🔒'
  }
  if (name === '回家模式') {
    AppStorage.Set(KEYS.LIGHT_ON, true)
    AppStorage.Set(KEYS.STUDY_LIGHT_ON, true)
    AppStorage.Set(KEYS.STUDY_LIGHT_LEVEL, 80)
    AppStorage.Set(KEYS.AC_ON, true)
    AppStorage.Set(KEYS.RANGE_HOOD_ON, false)
    AppStorage.Set(KEYS.PURIFIER_ON, true)
    AppStorage.Set(KEYS.PURIFIER_ON, true)
    AppStorage.Set(KEYS.DOOR_LOCKED, false)
    markDirty()
    return '欢迎回家 🏡\n已为您打开灯光、空调、净化器，门锁已解锁 🔓'
  }
  if (name === '观影模式') {
    AppStorage.Set(KEYS.LIGHT_ON, true)
    AppStorage.Set(KEYS.STUDY_LIGHT_ON, false)
    AppStorage.Set(KEYS.STUDY_LIGHT_LEVEL, 0)
    AppStorage.Set(KEYS.AC_ON, true)
    AppStorage.Set(KEYS.RANGE_HOOD_ON, false)
    AppStorage.Set(KEYS.PURIFIER_ON, true)
    AppStorage.Set(KEYS.CURTAIN_ON, false)
    AppStorage.Set(KEYS.CURTAIN_LEVEL, 0)
    AppStorage.Set(KEYS.PROJECTOR_ON, true)
    AppStorage.Set(KEYS.DOOR_LOCKED, true)
    markDirty()
    return '观影模式已启动 🎬\n灯光已调暗，投影仪已开启，窗帘已关闭 🎞️'
  }
  return '未找到场景"' + name + '"'
}

// =================================================================
//  6. AI 聊天记录持久化
// =================================================================

/** 聊天记录序列化格式 */
interface ChatRecord {
  id: string
  role: string   // 'user' | 'ai' 存为 string 避免枚举问题
  content: string
  time: string
}

/** 保存聊天记录到 Preferences */
export async function saveChatHistory(messages: ChatMessage[]): Promise<void> {
  if (prefsInstance === null) return

  // 构建 JSON 数组字符串（手动拼接避免 object literal 类型问题）
  let jsonArr = '['
  for (let i = 0; i < messages.length; i++) {
    const m = messages[i]
    if (i > 0) jsonArr += ','
    jsonArr += '{'
      + '"id":"' + escapeJson(m.id) + '",'
      + '"role":"' + escapeJson(m.role) + '",'
      + '"content":"' + escapeJson(m.content) + '",'
      + '"time":"' + escapeJson(m.time) + '"'
      + '}'
  }
  jsonArr += ']'

  await prefsInstance.put(KEY_CHAT_HISTORY, jsonArr)
  await prefsInstance.flush()
}

/** 从 Preferences 加载聊天记录 */
export async function loadChatHistory(): Promise<ChatMessage[]> {
  if (prefsInstance === null) return []

  const savedJson: string = (await prefsInstance.get(KEY_CHAT_HISTORY, '')) as string
  if (savedJson.length === 0) return []

  try {
    const raw: Object = JSON.parse(savedJson)
    const rawArr: ChatRecord[] = raw as ChatRecord[]
    const result: ChatMessage[] = []
    for (let i = 0; i < rawArr.length; i++) {
      const r = rawArr[i]
      result.push({
        id: r.id,
        role: (r.role === 'ai') ? 'ai' : 'user',
        content: r.content,
        time: r.time
      })
    }
    return result
  } catch (_e) {
    return []
  }
}

/** JSON 字符串转义 */
function escapeJson(s: string): string {
  let result = ''
  for (let i = 0; i < s.length; i++) {
    const ch = s[i]
    if (ch === '\\') result += '\\\\'
    else if (ch === '"') result += '\\"'
    else if (ch === '\n') result += '\\n'
    else if (ch === '\r') result += '\\r'
    else if (ch === '\t') result += '\\t'
    else result += ch
  }
  return result
}
