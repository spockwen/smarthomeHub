// ============================================================
// MQTT 通信服务 - MqttService.ets
//
// ★ 零第三方依赖：使用 HarmonyOS 内置 @ohos.net.webSocket
//    连接 EMQX WebSocket 端口 (8083)，内部实现 MQTT 3.1.1 协议
//
// 职责：
//   1. 管理与 EMQX 的 MQTT over WebSocket 连接
//   2. 订阅设备状态主题，接收设备上报的状态
//   3. 发布控制指令到设备的 command 主题
//   4. 自动重连、心跳保活
//   5. 接收设备状态后同步更新 AppStorage
//
// 主题设计：
//   订阅: home/device/{deviceId}/state   ← 接收设备状态
//   发布: home/device/{deviceId}/command  → 下发控制指令
//   订阅: home/devices/list               ← 接收设备列表
//   发送: home/system/heartbeat           → 心跳保活
//
// 通信链路：
//   鸿蒙APP  --WebSocket/MQTT-->  EMQX:8083  <--TCP/MQTT-->  Node.js模拟器
// ============================================================

import webSocket from '@ohos.net.webSocket'
import { util } from '@kit.ArkTS'
import { KEYS } from './DeviceStateService'

// =================================================================
//  ★ Part A — MQTT 3.1.1 协议编码器
// =================================================================

// ---- 数据包类型 ----
const PKT_CONNECT: number    = 1   // 连接请求
const PKT_CONNACK: number    = 2   // 连接确认
const PKT_PUBLISH: number    = 3   // 发布消息
const PKT_SUBSCRIBE: number  = 8   // 订阅请求
const PKT_SUBACK: number     = 9   // 订阅确认
const PKT_PINGREQ: number    = 12  // 心跳请求
const PKT_PINGRESP: number   = 13  // 心跳响应
const PKT_DISCONNECT: number = 14  // 断开连接

// ---- 固定值 ----
const MQTT_VERSION: number = 4        // MQTT 3.1.1
const PROTOCOL_NAME: string = 'MQTT'
const QOS_1: number = 1
const QOS_0: number = 0

// ---- 文本编解码器 ----
const textEncoder: util.TextEncoder = new util.TextEncoder()
const textDecoder: util.TextDecoder = new util.TextDecoder('utf-8')

/**
 * 编码"剩余长度"为变长字节序列 (MQTT §2.2.3)
 * 每个字节低7位存数据，最高位=1表示还有后续字节
 */
function encodeRemainingLength(length: number): Uint8Array {
  const buf: number[] = []
  let remaining: number = length
  do {
    let byte: number = remaining % 128
    remaining = Math.floor(remaining / 128)
    if (remaining > 0) {
      byte = byte | 0x80
    }
    buf.push(byte)
  } while (remaining > 0)
  return new Uint8Array(buf)
}

/**
 * 解码"剩余长度"：从 offset 开始读取，返回 { value, bytesRead }
 */
function decodeRemainingLength(data: Uint8Array, offset: number): Record<string, number> {
  let multiplier: number = 1
  let value: number = 0
  let bytesRead: number = 0
  let pos: number = offset

  for (let i: number = 0; i < 4; i++) {
    const byte: number = data[pos]
    pos++
    bytesRead++
    value += (byte & 0x7F) * multiplier
    if ((byte & 0x80) === 0) {
      break
    }
    multiplier *= 128
  }

  const result: Record<string, number> = {}
  result['value'] = value
  result['bytesRead'] = bytesRead
  return result
}

/**
 * 编码 MQTT UTF-8 字符串：2字节长度(大端) + UTF-8字节
 */
function encodeMqttString(str: string): Uint8Array {
  const utf8Bytes: Uint8Array = textEncoder.encodeInto(str)
  const len: number = utf8Bytes.length
  const result: Uint8Array = new Uint8Array(2 + len)
  result[0] = (len >> 8) & 0xFF   // 长度高字节
  result[1] = len & 0xFF           // 长度低字节
  for (let i: number = 0; i < len; i++) {
    result[2 + i] = utf8Bytes[i]
  }
  return result
}

/**
 * 从 Uint8Array 中读取 MQTT UTF-8 字符串，返回 { str, bytesRead }
 */
function decodeMqttString(data: Uint8Array, offset: number): Record<string, Object> {
  const len: number = ((data[offset] & 0xFF) << 8) | (data[offset + 1] & 0xFF)
  const strBytes: Uint8Array = new Uint8Array(len)
  for (let i: number = 0; i < len; i++) {
    strBytes[i] = data[offset + 2 + i]
  }
  const str: string = textDecoder.decode(strBytes)
  const result: Record<string, Object> = {}
  result['str'] = str
  result['bytesRead'] = 2 + len
  return result
}

/** 拼接多个 Uint8Array */
function concatUint8Arrays(arrays: Uint8Array[]): Uint8Array {
  let totalLen: number = 0
  for (let i: number = 0; i < arrays.length; i++) {
    totalLen += arrays[i].length
  }
  const result: Uint8Array = new Uint8Array(totalLen)
  let offset: number = 0
  for (let i: number = 0; i < arrays.length; i++) {
    for (let j: number = 0; j < arrays[i].length; j++) {
      result[offset + j] = arrays[i][j]
    }
    offset += arrays[i].length
  }
  return result
}

/** 构建 MQTT 数据包：固定头 + 可变头 + 载荷 */
function buildPacket(pktType: number, flags: number, body: Uint8Array): ArrayBuffer {
  const header: number = (pktType << 4) | flags
  const remLen: Uint8Array = encodeRemainingLength(body.length)
  const totalLen: number = 1 + remLen.length + body.length
  const result: Uint8Array = new Uint8Array(totalLen)
  result[0] = header
  for (let i: number = 0; i < remLen.length; i++) {
    result[1 + i] = remLen[i]
  }
  for (let i: number = 0; i < body.length; i++) {
    result[1 + remLen.length + i] = body[i]
  }
  return result.buffer
}

// =================================================================
//  ★ Part A.1 — MQTT 数据包构造函数
// =================================================================

/** 构建 CONNECT 包 */
function buildConnect(clientId: string, username: string, password: string, keepAlive: number): ArrayBuffer {
  // ---- 可变头 ----
  const protoName: Uint8Array = encodeMqttString(PROTOCOL_NAME)
  const protoLevel: Uint8Array = new Uint8Array([MQTT_VERSION])

  // Connect Flags: Username(bit7) | Password(bit6) | CleanSession(bit1)
  const connectFlags: number = 0x80 | 0x40 | 0x02
  const flagsByte: Uint8Array = new Uint8Array([connectFlags])

  // Keep Alive (2 bytes, big-endian)
  const keepAliveBytes: Uint8Array = new Uint8Array([
    (keepAlive >> 8) & 0xFF,
    keepAlive & 0xFF
  ])

  const varHeader: Uint8Array = concatUint8Arrays([
    protoName, protoLevel, flagsByte, keepAliveBytes
  ])

  // ---- 载荷：ClientId + Username + Password ----
  const clientIdBytes: Uint8Array = encodeMqttString(clientId)
  const usernameBytes: Uint8Array = encodeMqttString(username)
  const passwordBytes: Uint8Array = encodeMqttString(password)
  const payload: Uint8Array = concatUint8Arrays([clientIdBytes, usernameBytes, passwordBytes])

  const body: Uint8Array = concatUint8Arrays([varHeader, payload])
  return buildPacket(PKT_CONNECT, 0, body)
}

/** 构建 SUBSCRIBE 包 */
function buildSubscribe(packetId: number, topics: string[]): ArrayBuffer {
  // 可变头：包标识符 (2 bytes)
  const pktIdBytes: Uint8Array = new Uint8Array([
    (packetId >> 8) & 0xFF,
    packetId & 0xFF
  ])

  // 载荷：每个 topic 后跟 QoS 字节
  const payloadParts: Uint8Array[] = []
  for (let i: number = 0; i < topics.length; i++) {
    const topicBytes: Uint8Array = encodeMqttString(topics[i])
    const qosByte: Uint8Array = new Uint8Array([QOS_1])
    payloadParts.push(topicBytes)
    payloadParts.push(qosByte)
  }
  const payload: Uint8Array = concatUint8Arrays(payloadParts)

  const body: Uint8Array = concatUint8Arrays([pktIdBytes, payload])
  return buildPacket(PKT_SUBSCRIBE, 2, body)  // flags=2 for SUBSCRIBE
}

/** 构建 PUBLISH 包 (QoS 1) */
function buildPublish(topic: string, payloadStr: string, packetId: number): ArrayBuffer {
  // 可变头：主题名 + 包标识符
  const topicBytes: Uint8Array = encodeMqttString(topic)
  const pktIdBytes: Uint8Array = new Uint8Array([
    (packetId >> 8) & 0xFF,
    packetId & 0xFF
  ])

  // 载荷：消息内容 (UTF-8)
  const payloadBytes: Uint8Array = textEncoder.encodeInto(payloadStr)

  const body: Uint8Array = concatUint8Arrays([topicBytes, pktIdBytes, payloadBytes])
  // flags: QoS1 = 2 (0b0010)
  return buildPacket(PKT_PUBLISH, 2, body)
}

/** 构建 PINGREQ 包 (心跳) */
function buildPingReq(): ArrayBuffer {
  const body: Uint8Array = new Uint8Array(0)
  return buildPacket(PKT_PINGREQ, 0, body)
}

/** 构建 DISCONNECT 包 */
function buildDisconnect(): ArrayBuffer {
  const body: Uint8Array = new Uint8Array(0)
  return buildPacket(PKT_DISCONNECT, 0, body)
}

// =================================================================
//  ★ Part A.2 — MQTT 数据包解析器
// =================================================================

interface ParsedPacket {
  type: number       // 数据包类型 (PKT_xxx)
  topic: string      // PUBLISH 的主题
  payload: string    // PUBLISH 的载荷（UTF-8 文本）
  packetId: number   // 包标识符 (SUBACK / PUBACK)
}

/** 工厂函数：创建 ParsedPacket（避免 as 转换的类型问题） */
function makePacket(type: number, topic: string, payload: string, packetId: number): ParsedPacket {
  let p: ParsedPacket = { type: type, topic: topic, payload: payload, packetId: packetId }
  return p
}

/**
 * 解析收到的 MQTT 数据包
 * @return ParsedPacket | null (解析失败/PINGRESP 返回 null)
 */
function parsePacket(data: ArrayBuffer): ParsedPacket | null {
  if (data.byteLength < 2) {
    return null
  }

  const bytes: Uint8Array = new Uint8Array(data)
  const pktType: number = (bytes[0] >> 4) & 0x0F

  // 解析剩余长度
  const remLenInfo: Record<string, number> = decodeRemainingLength(bytes, 1)
  const remLen: number = remLenInfo['value']
  const headerLen: number = 1 + remLenInfo['bytesRead']
  const bodyStart: number = headerLen

  // ---- PINGRESP (心跳响应，无需处理) ----
  if (pktType === PKT_PINGRESP) {
    return null
  }

  // ---- CONNACK ----
  if (pktType === PKT_CONNACK) {
    // 格式: [Session Present(1)] [Return Code(1)]
    const returnCode: number = bytes[bodyStart + 1] & 0xFF
    return makePacket(PKT_CONNACK, '', '', returnCode)
  }

  // ---- SUBACK ----
  if (pktType === PKT_SUBACK) {
    const pktId: number = ((bytes[bodyStart] & 0xFF) << 8) | (bytes[bodyStart + 1] & 0xFF)
    return makePacket(PKT_SUBACK, '', '', pktId)
  }

  // ---- PUBLISH ----
  if (pktType === PKT_PUBLISH) {
    // 解析 Topic Name
    const topicResult: Record<string, Object> = decodeMqttString(bytes, bodyStart)
    const topic: string = topicResult['str'] as string
    const topicLen: number = topicResult['bytesRead'] as number

    // 包标识符 (QoS 1 时有 2 字节)
    const pktIdOffset: number = bodyStart + topicLen
    const pktId: number = ((bytes[pktIdOffset] & 0xFF) << 8) | (bytes[pktIdOffset + 1] & 0xFF)
    const payloadStart: number = pktIdOffset + 2

    // 载荷
    const payloadLen: number = bodyStart + remLen - payloadStart
    if (payloadLen <= 0) {
      return makePacket(PKT_PUBLISH, topic, '', pktId)
    }
    const payloadBytes: Uint8Array = new Uint8Array(payloadLen)
    for (let i: number = 0; i < payloadLen; i++) {
      payloadBytes[i] = bytes[payloadStart + i]
    }
    const payloadStr: string = textDecoder.decode(payloadBytes)

    return makePacket(PKT_PUBLISH, topic, payloadStr, pktId)
  }

  return null
}

// =================================================================
//  ★ Part B — 连接配置 & 状态管理
// =================================================================

/** EMQX WebSocket 地址 */
const BROKER_WS_URL: string = 'ws://10.0.2.2:8083/mqtt'
const MQTT_USERNAME: string = 'admin'
// ⚠️ 安全提示：请替换为你的 EMQX 实际密码
// EMQX Dashboard (localhost:18083) → 访问控制 → 认证 → 创建/查看密码
const MQTT_PASSWORD: string = 'YOUR_EMQX_PASSWORD'
const CLIENT_ID_PREFIX: string = 'harmony_app_'
const CONNECT_TIMEOUT: number = 10       // 连接超时（秒）
const KEEP_ALIVE_INTERVAL: number = 60   // 心跳间隔（秒）
const RECONNECT_DELAY: number = 5000     // 重连延迟（毫秒）

function generateClientId(): string {
  const r: number = Math.floor(Math.random() * 999999)
  return CLIENT_ID_PREFIX + r.toString()
}

// ---- 运行时状态 ----
let wsClient: webSocket.WebSocket | null = null
let isConnected: boolean = false
let packetIdCounter: number = 1
let reconnectTimer: number | null = null
let heartbeatTimer: number | null = null
let connackTimer: number | null = null

type ConnectionCallback = (connected: boolean) => void
let onConnectionChange: ConnectionCallback | null = null

// =================================================================
//  ★ Part C — 设备路由（与之前一致）
// =================================================================

const DEVICE_ID_TO_KEYS: Record<string, string[]> = {
  'living_room_light': [KEYS.LIGHT_ON],
  'study_light':       [KEYS.STUDY_LIGHT_ON, KEYS.STUDY_LIGHT_LEVEL],
  'range_hood':        [KEYS.RANGE_HOOD_ON],
  'air_purifier':      [KEYS.PURIFIER_ON],
  'ac':                [KEYS.AC_ON, KEYS.AC_TEMP],
  'curtain':           [KEYS.CURTAIN_ON, KEYS.CURTAIN_LEVEL],
  'projector':         [KEYS.PROJECTOR_ON],
  'door_lock':         [KEYS.DOOR_LOCKED]
}

const DEVICE_NAME_TO_ID: Record<string, string> = {
  '客厅主灯':   'living_room_light',
  '书房灯':     'study_light',
  '油烟机':     'range_hood',
  '空气净化器': 'air_purifier',
  '空调':       'ac',
  '电动窗帘':   'curtain',
  '投影仪':     'projector',
  '智能门锁':   'door_lock'
}

function stateTopic(deviceId: string): string {
  return 'home/device/' + deviceId + '/state'
}

function commandTopic(deviceId: string): string {
  return 'home/device/' + deviceId + '/command'
}

// =================================================================
//  ★ Part D — 对外接口
// =================================================================

export function setConnectionCallback(callback: ConnectionCallback): void {
  onConnectionChange = callback
}

export function getConnectionState(): boolean {
  return isConnected
}

// =================================================================
//  ★ Part E — 连接管理
// =================================================================

/**
 * 建立 WebSocket + MQTT 连接 (connectMqtt)
 *
 * 流程：
 *   1. WebSocket 连接 ws://10.0.2.2:8083/mqtt
 *   2. 发送 MQTT CONNECT 包
 *   3. 等待 CONNACK
 *   4. 订阅所有设备状态主题 (MQTT SUBSCRIBE)
 *   5. 启动心跳 (MQTT PINGREQ)
 */
export async function connectMqtt(): Promise<void> {
  // 清理旧连接
  if (wsClient !== null) {
    try {
      wsClient.close()
    } catch (_e) {
      // ignore
    }
    wsClient = null
  }

  try {
    const clientId: string = generateClientId()
    console.info('[MQTT-WS] 正在连接: ' + BROKER_WS_URL)
    console.info('[MQTT-WS] clientId: ' + clientId)

    // ---- Step 1: 建立 WebSocket 连接 ----
    wsClient = webSocket.createWebSocket()

    await new Promise<void>((resolve: (value: void) => void, reject: (reason: Error) => void): void => {
      // 连接超时
      const timeout: number = setTimeout((): void => {
        reject(new Error('WebSocket 连接超时'))
      }, CONNECT_TIMEOUT * 1000)

      wsClient!.on('open', (err: Error, _value: Object): void => {
        clearTimeout(timeout)
        if (err) {
          reject(new Error('WebSocket open 失败: ' + err.message))
          return
        }
        resolve()
      })

      wsClient!.on('error', (err: Error): void => {
        clearTimeout(timeout)
        reject(new Error('WebSocket error: ' + err.message))
      })

      // protocol: 'mqtt' 是必须的 — EMQX 要求 WebSocket 子协议声明
      wsClient!.connect(BROKER_WS_URL, { protocol: 'mqtt' }, (err: Error, _value: boolean): void => {
        if (err) {
          clearTimeout(timeout)
          reject(new Error('WebSocket connect 失败: ' + err.message))
        }
        // 'open' 事件也会触发，在那边 resolve
      })
    })

    console.info('[MQTT-WS] WebSocket 已连接，发送 MQTT CONNECT...')

    // ---- Step 2: 发送 MQTT CONNECT 包 ----
    const connectPkt: ArrayBuffer = buildConnect(clientId, MQTT_USERNAME, MQTT_PASSWORD, KEEP_ALIVE_INTERVAL)
    await wsSend(connectPkt)

    // 等待 CONNACK（带超时）
    const connackResult: number = await waitForConnack()
    if (connackResult !== 0) {
      throw new Error('MQTT CONNECT 被拒绝, 返回码: ' + connackResult.toString())
    }

    console.info('[MQTT-WS] ✅ MQTT 连接成功')
    isConnected = true
    if (onConnectionChange !== null) {
      onConnectionChange(true)
    }

    // ---- Step 3: 注册消息监听 ----
    wsClient.on('message', onWsMessage)
    wsClient.on('close', onWsClose)
    wsClient.on('error', onWsError)

    // ---- Step 4: 订阅所有设备状态主题 ----
    await subscribeAllTopics()

    // ---- Step 5: 启动心跳 ----
    startHeartbeat()

    // ---- Step 6: 启动自动同步 ----
    startAutoSync()

  } catch (err) {
    const errMsg: string = (err as Error).message
    console.error('[MQTT-WS] ❌ 连接失败: ' + errMsg)
    isConnected = false
    if (onConnectionChange !== null) {
      onConnectionChange(false)
    }
    scheduleReconnect()
  }
}

/** 等待 CONNACK */
function waitForConnack(): Promise<number> {
  return new Promise<number>((resolve: (v: number) => void, reject: (e: Error) => void): void => {
    connackTimer = setTimeout((): void => {
      connackTimer = null
      reject(new Error('等待 CONNACK 超时'))
    }, CONNECT_TIMEOUT * 1000)

    // 临时消息处理器（在 connect 期间捕获 CONNACK）
    const tempHandler: (err: Error, value: string | ArrayBuffer) => void =
      (err: Error, value: string | ArrayBuffer): void => {
        if (err) {
          return
        }
        // 字符串→二进制：用 charCodeAt 逐字节还原，避免 TextEncoder 破坏 >127 的字节
        let data1: ArrayBuffer
        if (typeof value === 'string') {
          const str: string = value as string
          const len: number = str.length
          const bytes: Uint8Array = new Uint8Array(len)
          for (let i: number = 0; i < len; i++) {
            bytes[i] = str.charCodeAt(i) & 0xFF
          }
          data1 = bytes.buffer as ArrayBuffer
        } else {
          data1 = value as ArrayBuffer
        }
        const packet: ParsedPacket | null = parsePacket(data1)
        if (packet !== null && packet.type === PKT_CONNACK) {
          if (connackTimer !== null) {
            clearTimeout(connackTimer)
            connackTimer = null
          }
          // 移除临时处理器
          if (wsClient !== null) {
            wsClient.off('message', tempHandler)
          }
          resolve(packet.packetId)  // 返回码在 packetId 字段
        }
      }

    if (wsClient !== null) {
      wsClient.on('message', tempHandler)
    }
  })
}

// =================================================================
//  ★ Part F — WebSocket 事件处理
// =================================================================

function onWsMessage(err: Error, value: string | ArrayBuffer): void {
  if (err) {
    console.error('[MQTT-WS] 消息接收错误: ' + err.message)
    return
  }
  if (value === null || value === undefined) {
    return
  }

  // 转换为 ArrayBuffer
  // 关键：MQTT over WebSocket 使用二进制帧，但某些 WebSocket 实现可能以 string 传递
  // 用 charCodeAt + &0xFF 逐字节还原，避免 TextEncoder 对 >127 字节做 UTF-8 多字节编码
  let data: ArrayBuffer
  if (typeof value === 'string') {
    const str: string = value as string
    const len: number = str.length
    const bytes: Uint8Array = new Uint8Array(len)
    for (let i: number = 0; i < len; i++) {
      bytes[i] = str.charCodeAt(i) & 0xFF
    }
    data = bytes.buffer as ArrayBuffer
  } else {
    data = value as ArrayBuffer
  }

  const packet: ParsedPacket | null = parsePacket(data)
  if (packet === null) {
    return  // PINGRESP / SUBACK / PUBACK / 无效包
  }

  // 只处理 PUBLISH 包
  if (packet.type === PKT_PUBLISH && packet.payload.length > 0) {
    handleMessage(packet.topic, packet.payload)
  }
}

function onWsClose(err: Error, _value: webSocket.CloseResult): void {
  if (err) {
    console.warn('[MQTT-WS] ⚠️ 连接关闭: ' + err.message)
  } else {
    console.warn('[MQTT-WS] ⚠️ 连接关闭')
  }
  isConnected = false
  if (onConnectionChange !== null) {
    onConnectionChange(false)
  }
  stopHeartbeat()
  scheduleReconnect()
}

function onWsError(err: Error): void {
  console.error('[MQTT-WS] ❌ WebSocket 错误: ' + err.message)
}

// =================================================================
//  ★ Part G — WebSocket 发送
// =================================================================

function wsSend(data: ArrayBuffer): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (e: Error) => void): void => {
    if (wsClient === null) {
      reject(new Error('WebSocket 未初始化'))
      return
    }
    wsClient.send(data, (err: Error): void => {
      if (err) {
        reject(new Error('发送失败: ' + err.message))
      } else {
        resolve()
      }
    })
  })
}

// =================================================================
//  ★ Part H — 订阅
// =================================================================

async function subscribeAllTopics(): Promise<void> {
  if (wsClient === null) {
    return
  }

  const topics: string[] = []
  const deviceIds: string[] = Object.keys(DEVICE_ID_TO_KEYS)

  // 收集所有需订阅的主题
  for (let i: number = 0; i < deviceIds.length; i++) {
    topics.push(stateTopic(deviceIds[i]))
  }
  topics.push('home/devices/list')
  topics.push('home/system/sync/request')

  // 分包订阅（MQTT 支持多 topic 批量订阅）
  const batchSize: number = 9  // 8 设备 state + 1 设备列表 = 9 个
  for (let start: number = 0; start < topics.length; start += batchSize) {
    const end: number = Math.min(start + batchSize, topics.length)
    const batch: string[] = []
    for (let i: number = start; i < end; i++) {
      batch.push(topics[i])
    }

    const pktId: number = nextPacketId()
    const subPkt: ArrayBuffer = buildSubscribe(pktId, batch)

    try {
      await wsSend(subPkt)
      console.info('[MQTT-WS]   ✓ 订阅包 #' + pktId.toString() + ': ' + batch.length.toString() + ' 个主题')
      for (let i: number = 0; i < batch.length; i++) {
        console.info('[MQTT-WS]     - ' + batch[i])
      }
    } catch (err) {
      console.error('[MQTT-WS]   ✗ 订阅失败: ' + (err as Error).message)
    }
  }

  console.info('[MQTT-WS] ✅ 已发送所有订阅请求')
}

function nextPacketId(): number {
  const id: number = packetIdCounter
  packetIdCounter++
  if (packetIdCounter > 65535) {
    packetIdCounter = 1
  }
  return id
}

// =================================================================
//  ★ Part I — 心跳
// =================================================================

function startHeartbeat(): void {
  stopHeartbeat()
  // 心跳间隔 = keepAlive / 2（MQTT 惯例）
  const interval: number = Math.floor(KEEP_ALIVE_INTERVAL / 2) * 1000
  heartbeatTimer = setInterval((): void => {
    if (!isConnected || wsClient === null) {
      return
    }
    try {
      const pingPkt: ArrayBuffer = buildPingReq()
      wsClient!.send(pingPkt, (_err: Error): void => { /* ignore */ })
    } catch (_err) {
      console.warn('[MQTT-WS] ⚠️ 心跳失败，连接可能已断开')
      isConnected = false
      if (onConnectionChange !== null) {
        onConnectionChange(false)
      }
      scheduleReconnect()
    }
  }, interval)
}

function stopHeartbeat(): void {
  if (heartbeatTimer !== null) {
    clearInterval(heartbeatTimer)
    heartbeatTimer = null
  }
}

// =================================================================
//  ★ Part J — 重连
// =================================================================

function scheduleReconnect(): void {
  if (reconnectTimer !== null) {
    return
  }
  console.info('[MQTT-WS] 🔄 将在 ' + (RECONNECT_DELAY / 1000).toString() + ' 秒后自动重连...')
  reconnectTimer = setTimeout((): void => {
    reconnectTimer = null
    if (!isConnected) {
      console.info('[MQTT-WS] 正在尝试重新连接...')
      connectMqtt()
    }
  }, RECONNECT_DELAY)
}

// =================================================================
//  ★ Part K — 消息处理
// =================================================================

function handleMessage(topic: string, payload: string): void {
  console.info('[MQTT-WS] 📩 收到消息: ' + topic)
  if (payload.length < 300) {
    console.info('[MQTT-WS]   内容: ' + payload)
  }

  try {
    const data: Object = JSON.parse(payload) as Object
    const dataObj: Record<string, Object> = data as Record<string, Object>

    // 处理同步请求
    if (topic === 'home/system/sync/request') {
      handleSyncRequest(dataObj)
      return
    }

    const parts: string[] = topic.split('/')
    if (parts.length >= 4 && parts[0] === 'home' && parts[1] === 'device') {
      const deviceId: string = parts[2]
      syncDeviceState(deviceId, dataObj)
    }
  } catch (err) {
    console.error('[MQTT-WS] 消息解析失败: ' + (err as Error).message)
  }
}

function syncDeviceState(deviceId: string, data: Record<string, Object>): void {
  const keys: string[] | undefined = DEVICE_ID_TO_KEYS[deviceId]
  if (keys === undefined) {
    console.warn('[MQTT-WS] 未知设备ID: ' + deviceId)
    return
  }

  if (deviceId === 'door_lock') {
    if (typeof data['locked'] === 'boolean') {
      AppStorage.set(KEYS.DOOR_LOCKED, data['locked'] as boolean)
      console.info('[MQTT-WS] 🔒 智能门锁 → ' + ((data['locked'] as boolean) ? '已锁定' : '已解锁'))
    }
  } else if (deviceId === 'ac') {
    if (typeof data['on'] === 'boolean') {
      AppStorage.set(KEYS.AC_ON, data['on'] as boolean)
    }
    if (typeof data['temperature'] === 'number') {
      AppStorage.set(KEYS.AC_TEMP, data['temperature'] as number)
    }
    const acOn: boolean = data['on'] as boolean
    const acTemp: number = data['temperature'] as number
    console.info('[MQTT-WS] ❄️ 空调 → ' + (acOn ? '开 ' + acTemp.toString() + '℃' : '关'))
  } else if (deviceId === 'study_light') {
    if (typeof data['on'] === 'boolean') {
      AppStorage.set(KEYS.STUDY_LIGHT_ON, data['on'] as boolean)
    }
    if (typeof data['brightness'] === 'number') {
      AppStorage.set(KEYS.STUDY_LIGHT_LEVEL, data['brightness'] as number)
    }
    const slOn: boolean = data['on'] as boolean
    const slBright: number = data['brightness'] as number
    console.info('[MQTT-WS] 💡 书房灯 → ' + (slOn ? '开 ' + slBright.toString() + '%' : '关'))
  } else if (deviceId === 'curtain') {
    if (typeof data['on'] === 'boolean') {
      AppStorage.set(KEYS.CURTAIN_ON, data['on'] as boolean)
    }
    if (typeof data['level'] === 'number') {
      AppStorage.set(KEYS.CURTAIN_LEVEL, data['level'] as number)
    }
    const ctOn: boolean = data['on'] as boolean
    const ctLevel: number = data['level'] as number
    console.info('[MQTT-WS] 🪟 窗帘 → ' + (ctOn ? '开 ' + ctLevel.toString() + '%' : '关'))
  } else {
    if (typeof data['on'] === 'boolean') {
      AppStorage.set(keys[0], data['on'] as boolean)
      const devOn: boolean = data['on'] as boolean
      console.info('[MQTT-WS] 设备 ' + deviceId + ' → ' + (devOn ? '开启' : '关闭'))
    }
  }
}

// =================================================================
//  ★ Part K.1 — 状态同步
// =================================================================

/** 处理同步请求 */
function handleSyncRequest(data: Record<string, Object>): void {
  console.info('[MQTT-WS] 🔄 收到同步请求')

  // 发送所有设备当前状态到 APP 主题
  publishAllDeviceStates()
}

/** 发送所有设备状态到 APP 主题 */
async function publishAllDeviceStates(): Promise<void> {
  if (wsClient === null || !isConnected) {
    console.warn('[MQTT-WS] ⚠️ 未连接，无法同步状态')
    return
  }

  console.info('[MQTT-WS] 📤 同步所有设备状态到 APP...')

  // 客厅主灯
  await publishDeviceStateToApp('living_room_light',
    `{"on":${AppStorage.Get<boolean>(KEYS.LIGHT_ON) ?? true}}`)

  // 书房灯
  await publishDeviceStateToApp('study_light',
    `{"on":${AppStorage.Get<boolean>(KEYS.STUDY_LIGHT_ON) ?? true},"brightness":${AppStorage.Get<number>(KEYS.STUDY_LIGHT_LEVEL) ?? 100}}`)

  // 油烟机
  await publishDeviceStateToApp('range_hood',
    `{"on":${AppStorage.Get<boolean>(KEYS.RANGE_HOOD_ON) ?? true}}`)

  // 空气净化器
  await publishDeviceStateToApp('air_purifier',
    `{"on":${AppStorage.Get<boolean>(KEYS.PURIFIER_ON) ?? true}}`)

  // 空调
  await publishDeviceStateToApp('ac',
    `{"on":${AppStorage.Get<boolean>(KEYS.AC_ON) ?? true},"temperature":${AppStorage.Get<number>(KEYS.AC_TEMP) ?? 24}}`)

  // 电动窗帘
  await publishDeviceStateToApp('curtain',
    `{"on":${AppStorage.Get<boolean>(KEYS.CURTAIN_ON) ?? true},"level":${AppStorage.Get<number>(KEYS.CURTAIN_LEVEL) ?? 100}}`)

  // 投影仪
  await publishDeviceStateToApp('projector',
    `{"on":${AppStorage.Get<boolean>(KEYS.PROJECTOR_ON) ?? false}}`)

  // 智能门锁
  await publishDeviceStateToApp('door_lock',
    `{"locked":${AppStorage.Get<boolean>(KEYS.DOOR_LOCKED) ?? true}}`)

  console.info('[MQTT-WS] ✅ 所有设备状态已同步')
}

/** 发送单个设备状态到 APP 主题 */
async function publishDeviceStateToApp(deviceId: string, jsonState: string): Promise<void> {
  if (wsClient === null || !isConnected) {
    return
  }

  const topic: string = stateTopic(deviceId) + '/app'

  // 在 JSON 末尾追加时间戳（替代旧版 indexed access）
  const payload: string = jsonState.substring(0, jsonState.length - 1) +
    ',"timestamp":' + Date.now() + '}'

  try {
    const pktId: number = nextPacketId()
    const pubPkt: ArrayBuffer = buildPublish(topic, payload, pktId)
    await wsSend(pubPkt)
    console.info('[MQTT-WS]   ✓ ' + deviceId + ' 状态已同步')
  } catch (err) {
    console.error('[MQTT-WS]   ✗ ' + deviceId + ' 同步失败: ' + (err as Error).message)
  }
}

/** 定时同步状态（每120ms） */
let autoSyncTimer: number | null = null

export function startAutoSync(): void {
  stopAutoSync()
  autoSyncTimer = setInterval((): void => {
    if (isConnected) {
      publishAllDeviceStates()
    }
  }, 120)
}

export function stopAutoSync(): void {
  if (autoSyncTimer !== null) {
    clearInterval(autoSyncTimer)
    autoSyncTimer = null
  }
}

// =================================================================
//  ★ Part L — 指令发布
// =================================================================

async function publishCommand(deviceId: string, action: string, value?: number): Promise<void> {
  if (wsClient === null || !isConnected) {
    console.warn('[MQTT-WS] ⚠️ 未连接，无法发送指令')
    return
  }

  const topic: string = commandTopic(deviceId)

  // 手动拼 JSON
  let payload: string = '{"action":"' + action + '"'
  if (value !== undefined) {
    payload += ',"value":' + value.toString()
  }
  payload += '}'

  try {
    const pktId: number = nextPacketId()
    const pubPkt: ArrayBuffer = buildPublish(topic, payload, pktId)
    await wsSend(pubPkt)
    console.info('[MQTT-WS] 📤 已发送指令 → ' + topic)
    console.info('[MQTT-WS]   内容: ' + payload)
  } catch (err) {
    const errMsg: string = (err as Error).message
    console.error('[MQTT-WS] ❌ 发送失败: ' + errMsg)
    if (isConnected) {
      isConnected = false
      if (onConnectionChange !== null) {
        onConnectionChange(false)
      }
      scheduleReconnect()
    }
  }
}

// =================================================================
//  ★ Part M — 便捷方法（供页面调用）
// =================================================================

export async function sendToggleCommand(deviceName: string, on: boolean): Promise<void> {
  const deviceId: string | undefined = DEVICE_NAME_TO_ID[deviceName]
  if (deviceId === undefined) {
    console.warn('[MQTT-WS] 未找到设备: ' + deviceName)
    return
  }
  await publishCommand(deviceId, on ? 'on' : 'off')
}

export async function sendAdjustCommand(deviceName: string, value: number): Promise<void> {
  const deviceId: string | undefined = DEVICE_NAME_TO_ID[deviceName]
  if (deviceId === undefined) {
    console.warn('[MQTT-WS] 未找到设备: ' + deviceName)
    return
  }

  if (deviceName === '空调') {
    await publishCommand(deviceId, 'set_temperature', value)
  } else if (deviceName === '书房灯') {
    await publishCommand(deviceId, 'set_brightness', value)
  } else if (deviceName === '电动窗帘') {
    await publishCommand(deviceId, 'set_level', value)
  }
}

export async function sendSceneCommand(sceneName: string): Promise<void> {
  if (sceneName === '离家模式') {
    await publishCommand('living_room_light', 'scene_leave')
  } else if (sceneName === '回家模式') {
    await publishCommand('living_room_light', 'scene_home')
  } else if (sceneName === '观影模式') {
    await publishCommand('living_room_light', 'set_brightness', 20)
    await publishCommand('projector', 'on')
    await publishCommand('curtain', 'set_level', 0)
  }
}

// =================================================================
//  ★ Part N — 断开连接
// =================================================================

export async function disconnectMqtt(): Promise<void> {
  console.info('[MQTT-WS] 正在断开连接...')

  // 清除定时器
  if (reconnectTimer !== null) {
    clearTimeout(reconnectTimer)
    reconnectTimer = null
  }
  if (connackTimer !== null) {
    clearTimeout(connackTimer)
    connackTimer = null
  }
  stopHeartbeat()
  stopAutoSync()

  // 发送 DISCONNECT
  if (wsClient !== null && isConnected) {
    try {
      const dscPkt: ArrayBuffer = buildDisconnect()
      await wsSend(dscPkt)
    } catch (_e) {
      // ignore
    }
  }

  // 关闭 WebSocket
  if (wsClient !== null) {
    try {
      wsClient.off('message', onWsMessage)
      wsClient.off('close', onWsClose)
      wsClient.off('error', onWsError)
      wsClient.close()
      console.info('[MQTT-WS] 👋 已断开连接')
    } catch (err) {
      console.error('[MQTT-WS] 断开失败: ' + (err as Error).message)
    }
    wsClient = null
  }

  isConnected = false
  if (onConnectionChange !== null) {
    onConnectionChange(false)
  }
}
