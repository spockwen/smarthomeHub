// ============================================================
// 智能家居设备模拟器 - simulator.js
//
// 功能：
//   1. 连接 EMQX MQTT 服务端
//   2. 订阅所有设备的 command 主题，接收 APP 下发的指令
//   3. 处理指令后，将设备最新状态发布到 state 主题
//   4. 定时发送心跳包，上报设备在线状态
//   5. 提供 Web 可视化面板（Express + WebSocket）
//
// 使用方法：
//   1. 确保 Docker Desktop 已启动，EMQX 容器运行中
//   2. npm install
//   3. npm start
//   4. 浏览器打开 http://localhost:3000 查看可视化面板
// ============================================================

require('dotenv').config()
const mqtt = require('mqtt')
const express = require('express')
const http = require('http')
const { WebSocketServer } = require('ws')
const path = require('path')
const { DEVICES, TOPICS, INTERVALS, ENVIRONMENT, TIME_SIMULATION, AUTOMATIONS } = require('./config')

// ============================================================
//  1. Express + WebSocket 服务
// ============================================================

const WEB_PORT = process.env.WEB_PORT || 3000

const app = express()
const server = http.createServer(app)
const wss = new WebSocketServer({ server })

// 静态文件服务
app.use(express.static(path.join(__dirname, 'public')))

// WebSocket 连接管理
const wsClients = new Set()

wss.on('connection', (ws) => {
  wsClients.add(ws)
  console.log(`🌐 Web 客户端已连接 (共 ${wsClients.size} 个)`)

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString())
      handleWebCommand(msg, ws)
    } catch (e) {
      console.error('Web 消息解析失败:', e.message)
    }
  })

  ws.on('close', () => {
    wsClients.delete(ws)
    console.log(`🌐 Web 客户端断开 (剩余 ${wsClients.size} 个)`)
  })
})

/** 向所有 Web 客户端广播消息 */
function broadcastToWeb(msg) {
  const data = JSON.stringify(msg)
  wsClients.forEach(ws => {
    if (ws.readyState === 1) {  // WebSocket.OPEN
      ws.send(data)
    }
  })
}

// ============================================================
//  2. 连接 EMQX
// ============================================================

const brokerUrl = process.env.MQTT_BROKER_URL || 'mqtt://127.0.0.1:1883'
const options = {
  username: process.env.MQTT_USERNAME || 'admin',
  password: process.env.MQTT_PASSWORD || 'YOUR_EMQX_PASSWORD',  // ⚠️ 请替换为你的 EMQX 密码
  clientId: process.env.MQTT_CLIENT_ID || 'simulator_node_01',
  clean: true,
  connectTimeout: 5000,
  reconnectPeriod: 3000
}

console.log('========================================')
console.log('  智能家居设备模拟器')
console.log('========================================')
console.log(`📡 MQTT 服务: ${brokerUrl}`)
console.log(`🌐 Web 面板:  http://localhost:${WEB_PORT}`)
console.log('')

const client = mqtt.connect(brokerUrl, options)

// ============================================================
//  3. 设备运行时状态
// ============================================================

const deviceStates = {}
DEVICES.forEach(device => {
  deviceStates[device.id] = JSON.parse(JSON.stringify(device.initialState))
  // 添加最后操作时间戳
  deviceStates[device.id].lastUpdate = Date.now()
  deviceStates[device.id].lastSource = 'simulator'  // 'simulator' 或 'app'
})

// 同步状态记录（用于比较最后操作）
const syncState = {
  lastSyncTime: 0,
  pendingSync: false,
  appDeviceStates: {}  // 存储来自 APP 的状态
}

// 室内环境状态
const environmentState = {
  roomTemperature: ENVIRONMENT.INITIAL_ROOM_TEMP,
  targetTemperature: ENVIRONMENT.INITIAL_ROOM_TEMP,
  humidity: 55,                     // 模拟湿度 (%)
  acCooling: false,                 // 空调是否在制冷
  lastUpdate: Date.now()
}

// 时间模拟状态
const timeSimulationState = {
  currentHour: TIME_SIMULATION.INITIAL_HOUR,
  currentMinute: TIME_SIMULATION.INITIAL_MINUTE,
  currentSecond: 0,
  paused: false,  // 是否暂停
  executedAutomations: new Set()  // 记录已执行的定时任务（避免重复执行）
}

// ============================================================
//  4. MQTT 连接事件处理
// ============================================================

client.on('connect', () => {
  console.log('✅ 已连接 EMQX MQTT 服务端')
  console.log(`   客户端ID: ${options.clientId}`)
  console.log('')

  // 订阅所有设备的 command 主题
  const subscribeTopics = DEVICES.map(d => d.commandTopic)
  subscribeTopics.push(TOPICS.HEARTBEAT)
  subscribeTopics.push(TOPICS.ROOM_TEMPERATURE + '/set')
  // 订阅 APP 状态同步主题
  DEVICES.forEach(d => subscribeTopics.push(d.stateTopic + '/app'))

  client.subscribe(subscribeTopics, { qos: 1 }, (err) => {
    if (err) {
      console.error('❌ 订阅失败:', err.message)
      return
    }
    console.log('📡 已订阅以下主题:')
    subscribeTopics.forEach(t => console.log(`   - ${t}`))
    console.log('')

    // 通知 Web 客户端 MQTT 已连接
    broadcastToWeb({ type: 'mqtt_status', connected: true })

    // 启动后延迟发布初始状态
    setTimeout(() => {
      publishDeviceList()
      publishAllDeviceStates()
      publishRoomTemperature()
      startTemperatureSimulation()
      startTimeSimulation()
      startAutoSync()
      console.log('🚀 模拟器就绪，等待指令...\n')
    }, INTERVALS.STARTUP_DELAY)
  })
})

client.on('error', (err) => {
  console.error('❌ 连接错误:', err.message)
  broadcastToWeb({ type: 'mqtt_status', connected: false })
})

client.on('offline', () => {
  console.log('⚠️  已断开连接，正在重连...')
  broadcastToWeb({ type: 'mqtt_status', connected: false })
})

client.on('reconnect', () => {
  console.log('🔄 正在重新连接...')
})

// ============================================================
//  5. MQTT 消息接收处理
// ============================================================

client.on('message', (topic, message) => {
  const msgStr = message.toString()

  // 心跳请求
  if (topic === TOPICS.HEARTBEAT) {
    publishHeartbeat()
    return
  }

  // 室温设置
  if (topic === TOPICS.ROOM_TEMPERATURE + '/set') {
    handleRoomTemperatureCommand(msgStr)
    return
  }

  // 时间设置
  if (topic === 'home/system/time/set') {
    handleTimeSettingCommand(msgStr)
    return
  }

  // 自动化控制
  if (topic === 'home/automation/control') {
    handleAutomationCommand(msgStr)
    return
  }

  // 设备状态同步（来自 APP）
  if (topic.match(/^home\/device\/.+\/state\/app$/)) {
    handleAppStateSync(topic, msgStr)
    return
  }

  // 查找对应的设备
  const device = DEVICES.find(d => d.commandTopic === topic)
  if (!device) {
    console.log(`⚠️  未知主题: ${topic}`)
    return
  }

  console.log(`\n📩 收到 MQTT 指令 [${device.name}] ${topic}`)
  console.log(`   原始消息: ${msgStr}`)

  let cmd
  try {
    cmd = JSON.parse(msgStr)
  } catch (e) {
    console.log(`   ❌ JSON 解析失败: ${e.message}`)
    return
  }

  // 通知 Web 客户端
  broadcastToWeb({ type: 'command_received', data: `${device.name} → ${cmd.action}` })

  handleCommand(device, cmd)
})

// ============================================================
//  6. Web 指令处理
// ============================================================

function handleWebCommand(msg, ws) {
  if (msg.type === 'query_all') {
    // Web 客户端请求所有设备状态
    ws.send(JSON.stringify({ type: 'all_states', data: deviceStates }))
    ws.send(JSON.stringify({ type: 'mqtt_status', connected: client.connected }))
    ws.send(JSON.stringify({
      type: 'temperature_update',
      data: {
        temperature: Math.round(environmentState.roomTemperature * 10) / 10,
        humidity: environmentState.humidity,
        targetTemperature: environmentState.targetTemperature,
        acCooling: environmentState.acCooling,
        outdoorTemperature: ENVIRONMENT.OUTDOOR_TEMP
      }
    }))
    // 发送时间状态
    ws.send(JSON.stringify({
      type: 'time_update',
      data: getTimeState()
    }))
    // 发送自动化状态
    ws.send(JSON.stringify({
      type: 'automations_update',
      data: getAutomationsState()
    }))
    return
  }

  if (msg.type === 'command') {
    const device = DEVICES.find(d => d.id === msg.deviceId)
    if (!device) {
      console.log(`⚠️  Web 指令: 未知设备 ${msg.deviceId}`)
      return
    }

    console.log(`\n🌐 Web 指令 [${device.name}] → ${msg.action}`)
    broadcastToWeb({ type: 'command_received', data: `Web: ${device.name} → ${msg.action}` })

    const cmd = { action: msg.action }
    if (msg.value !== undefined) cmd.value = msg.value
    handleCommand(device, cmd)
  }

  if (msg.type === 'set_temperature') {
    console.log(`\n🌐 Web 指令: 设置室温 → ${msg.temperature}℃`)
    handleRoomTemperatureCommand(JSON.stringify({ temperature: msg.temperature, humidity: msg.humidity }))
  }

  if (msg.type === 'set_time') {
    console.log(`\n🌐 Web 指令: 设置时间 → ${msg.hour}:${msg.minute}`)
    handleTimeSettingCommand(JSON.stringify(msg))
  }

  if (msg.type === 'automation_control') {
    console.log(`\n🌐 Web 指令: 自动化控制 → ${msg.action}`)
    handleAutomationCommand(JSON.stringify(msg))
  }

  if (msg.type === 'refresh_sync') {
    console.log(`\n🌐 Web 指令: 刷新状态同步`)
    forceSyncWithApp()
  }

  if (msg.type === 'device_register') {
    console.log(`\n🌐 Web 指令: 设备注册`)
    handleDeviceRegistration(msg.device, ws)
  }
}

// ============================================================
//  7. 指令处理逻辑
// ============================================================

function handleCommand(device, cmd) {
  const state = deviceStates[device.id]
  let changed = false
  const now = Date.now()

  switch (cmd.action) {
    case 'on':
      if (device.id === 'door_lock') {
        state.locked = false
        console.log(`   🔓 门锁已解锁`)
      } else {
        state.on = true
        console.log(`   ✅ ${device.name} 已开启`)
      }
      changed = true
      break

    case 'off':
      if (device.id === 'door_lock') {
        state.locked = true
        console.log(`   🔒 门锁已锁定`)
      } else {
        state.on = false
        console.log(`   ⏹️  ${device.name} 已关闭`)
      }
      changed = true
      break

    case 'toggle':
      if (device.id === 'door_lock') {
        state.locked = !state.locked
        console.log(`   ${state.locked ? '🔒 门锁已锁定' : '🔓 门锁已解锁'}`)
      } else {
        state.on = !state.on
        console.log(`   ${state.on ? '✅' : '⏹️'} ${device.name} 已${state.on ? '开启' : '关闭'}`)
      }
      changed = true
      break

    case 'set_brightness':
      if (device.type === 'light' && typeof cmd.value === 'number') {
        state.brightness = Math.max(0, Math.min(100, cmd.value))
        state.on = state.brightness > 0
        console.log(`   💡 亮度已调至 ${state.brightness}%`)
        changed = true
      }
      break

    case 'set_temperature':
      if (device.type === 'ac' && typeof cmd.value === 'number') {
        state.temperature = Math.max(16, Math.min(30, cmd.value))
        state.on = true
        console.log(`   ❄️  温度已调至 ${state.temperature}℃`)
        changed = true
      }
      break

    case 'set_level':
      if (device.type === 'curtain' && typeof cmd.value === 'number') {
        state.level = Math.max(0, Math.min(100, cmd.value))
        state.on = state.level > 0
        console.log(`   🪟 窗帘开合度已调至 ${state.level}%`)
        changed = true
      }
      break

    case 'scene_home':
      console.log('   🏡 执行回家模式')
      applyScene('home')
      return  // applyScene 已经处理了状态发布

    case 'scene_leave':
      console.log('   🏠 执行离家模式')
      applyScene('leave')
      return  // applyScene 已经处理了状态发布

    case 'scene_movie':
      console.log('   🎬 执行观影模式')
      applyScene('movie')
      return  // applyScene 已经处理了状态发布

    case 'query':
      console.log(`   📊 查询 ${device.name} 状态`)
      publishDeviceState(device)
      publishDeviceStateToApp(device)
      // 也推送到 Web
      broadcastToWeb({
        type: 'state_update',
        data: { id: device.id, name: device.name, ...state, timestamp: now }
      })
      return

    default:
      console.log(`   ⚠️  未知指令: ${cmd.action}`)
      return
  }

  if (changed) {
    // 更新时间戳和来源
    state.lastUpdate = now
    state.lastSource = 'simulator'

    // 推送状态到 Web（即时）
    broadcastToWeb({
      type: 'state_update',
      data: { id: device.id, name: device.name, ...state, timestamp: now }
    })

    // 发布到 MQTT（确保鸿蒙应用能立即接收）
    setTimeout(() => {
      publishDeviceState(device)
      publishDeviceStateToApp(device)
    }, INTERVALS.STATE_PUBLISH)
  }
}

// ============================================================
//  8. 场景模式
// ============================================================

function applyScene(scene) {
  const now = Date.now()

  if (scene === 'leave') {
    console.log('   🏠 执行离家模式 - 关闭所有灯光和设备')
    Object.keys(deviceStates).forEach(id => {
      if (id === 'door_lock') {
        deviceStates[id].locked = true
        deviceStates[id].lastUpdate = now
        deviceStates[id].lastSource = 'simulator'
      } else {
        deviceStates[id].on = false
        deviceStates[id].lastUpdate = now
        deviceStates[id].lastSource = 'simulator'
      }
    })
    deviceStates['curtain'].level = 0
    deviceStates['curtain'].lastUpdate = now
    deviceStates['study_light'].brightness = 0
    deviceStates['study_light'].lastUpdate = now
  } else if (scene === 'home') {
    console.log('   🏡 执行回家模式 - 开启灯光、空调、净化器')
    deviceStates['living_room_light'].on = true
    deviceStates['living_room_light'].brightness = 100
    deviceStates['living_room_light'].lastUpdate = now
    deviceStates['living_room_light'].lastSource = 'simulator'

    deviceStates['study_light'].on = true
    deviceStates['study_light'].brightness = 80
    deviceStates['study_light'].lastUpdate = now
    deviceStates['study_light'].lastSource = 'simulator'

    deviceStates['ac'].on = true
    deviceStates['ac'].temperature = 26
    deviceStates['ac'].lastUpdate = now
    deviceStates['ac'].lastSource = 'simulator'

    deviceStates['air_purifier'].on = true
    deviceStates['air_purifier'].lastUpdate = now
    deviceStates['air_purifier'].lastSource = 'simulator'

    deviceStates['door_lock'].locked = false
    deviceStates['door_lock'].lastUpdate = now
    deviceStates['door_lock'].lastSource = 'simulator'
  } else if (scene === 'movie') {
    console.log('   🎬 执行观影模式 - 调暗灯光、关闭窗帘、开启投影仪')
    deviceStates['living_room_light'].on = true
    deviceStates['living_room_light'].brightness = 20
    deviceStates['living_room_light'].lastUpdate = now
    deviceStates['living_room_light'].lastSource = 'simulator'

    deviceStates['study_light'].on = false
    deviceStates['study_light'].lastUpdate = now
    deviceStates['study_light'].lastSource = 'simulator'

    deviceStates['curtain'].on = true
    deviceStates['curtain'].level = 0
    deviceStates['curtain'].lastUpdate = now
    deviceStates['curtain'].lastSource = 'simulator'

    deviceStates['projector'].on = true
    deviceStates['projector'].lastUpdate = now
    deviceStates['projector'].lastSource = 'simulator'
  }

  // 检查场景自动化
  const automation = AUTOMATIONS.find(a => a.trigger.type === 'scene' && a.trigger.sceneName === `scene_${scene}`)
  if (automation && automation.enabled) {
    console.log(`   🤖 触发自动化: ${automation.name}`)
    executeAutomationActions(automation)
  }

  // 推送所有设备状态到 Web
  broadcastToWeb({ type: 'all_states', data: deviceStates })

  // 立即发布所有设备状态到 MQTT（确保鸿蒙应用能立即接收）
  console.log('   📤 同步所有设备状态到鸿蒙应用...')
  DEVICES.forEach((device, index) => {
    setTimeout(() => {
      publishDeviceState(device)
      // 同时发布到 APP 状态主题
      publishDeviceStateToApp(device)
    }, index * 50)  // 每个设备间隔 50ms，避免消息风暴
  })
}

// ============================================================
//  9. MQTT 消息发布
// ============================================================

function publishDeviceState(device) {
  const state = deviceStates[device.id]
  const payload = JSON.stringify({
    id: device.id,
    name: device.name,
    icon: device.icon,
    room: device.room,
    ...state,
    timestamp: Date.now()
  })

  client.publish(device.stateTopic, payload, { qos: 1 }, (err) => {
    if (err) {
      console.log(`   ❌ 发布失败 [${device.name}]: ${err.message}`)
    } else {
      console.log(`   📤 已发布状态 [${device.name}] → ${device.stateTopic}`)
    }
  })
}

/** 发布设备状态到 APP 状态主题 */
function publishDeviceStateToApp(device) {
  const state = deviceStates[device.id]
  const payload = JSON.stringify({
    id: device.id,
    name: device.name,
    icon: device.icon,
    room: device.room,
    ...state,
    timestamp: Date.now()
  })

  const appTopic = device.stateTopic + '/app'
  client.publish(appTopic, payload, { qos: 1 }, (err) => {
    if (err) {
      console.log(`   ❌ APP 同步失败 [${device.name}]: ${err.message}`)
    } else {
      console.log(`   📱 APP 同步 [${device.name}] → ${appTopic}`)
    }
  })
}

function publishAllDeviceStates() {
  console.log('\n📤 发布所有设备状态...')
  DEVICES.forEach((device, index) => {
    setTimeout(() => publishDeviceState(device), index * 200)
  })
}

function publishDeviceList() {
  const list = DEVICES.map(d => ({
    id: d.id, name: d.name, icon: d.icon, room: d.room, type: d.type
  }))

  const payload = JSON.stringify({
    devices: list, count: list.length, timestamp: Date.now()
  })

  client.publish(TOPICS.DEVICE_LIST, payload, { qos: 1 }, (err) => {
    if (err) {
      console.log(`❌ 设备列表发布失败: ${err.message}`)
    } else {
      console.log(`📋 已发布设备列表 (${list.length} 个设备) → ${TOPICS.DEVICE_LIST}`)
    }
  })
}

function publishHeartbeat() {
  const onlineDevices = Object.keys(deviceStates).filter(id => deviceStates[id].online !== false)
  const payload = JSON.stringify({
    simulator: options.clientId,
    onlineCount: onlineDevices.length,
    totalCount: DEVICES.length,
    timestamp: Date.now()
  })
  client.publish(TOPICS.HEARTBEAT, payload, { qos: 0 })
}

// ============================================================
//  室内温度管理
// ============================================================

/** 发布室温状态 */
function publishRoomTemperature() {
  const payload = JSON.stringify({
    temperature: Math.round(environmentState.roomTemperature * 10) / 10,
    humidity: environmentState.humidity,
    targetTemperature: environmentState.targetTemperature,
    acCooling: environmentState.acCooling,
    outdoorTemperature: ENVIRONMENT.OUTDOOR_TEMP,
    timestamp: Date.now()
  })

  client.publish(TOPICS.ROOM_TEMPERATURE, payload, { qos: 1 }, (err) => {
    if (err) {
      console.log(`❌ 室温发布失败: ${err.message}`)
    } else {
      console.log(`🌡️  室温已发布: ${environmentState.roomTemperature.toFixed(1)}℃ (目标: ${environmentState.targetTemperature}℃)`)
    }
  })

  // 同时推送到 Web 面板
  broadcastToWeb({
    type: 'temperature_update',
    data: {
      temperature: Math.round(environmentState.roomTemperature * 10) / 10,
      humidity: environmentState.humidity,
      targetTemperature: environmentState.targetTemperature,
      acCooling: environmentState.acCooling,
      outdoorTemperature: ENVIRONMENT.OUTDOOR_TEMP
    }
  })
}

/** 处理室温设置指令 */
function handleRoomTemperatureCommand(msgStr) {
  console.log(`\n🌡️  收到室温设置指令: ${msgStr}`)

  let cmd
  try {
    cmd = JSON.parse(msgStr)
  } catch (e) {
    console.log(`   ❌ JSON 解析失败: ${e.message}`)
    return
  }

  if (typeof cmd.temperature === 'number') {
    const newTemp = Math.max(10, Math.min(40, cmd.temperature))
    environmentState.roomTemperature = newTemp
    environmentState.targetTemperature = newTemp
    console.log(`   ✅ 室温已设置为: ${newTemp}℃`)
    publishRoomTemperature()
  }

  if (typeof cmd.humidity === 'number') {
    const newHumidity = Math.max(20, Math.min(90, cmd.humidity))
    environmentState.humidity = newHumidity
    console.log(`   ✅ 湿度已设置为: ${newHumidity}%`)
    publishRoomTemperature()
  }
}

/** 启动温度模拟 */
function startTemperatureSimulation() {
  console.log('🌡️  温度模拟已启动')
  console.log(`   空调制冷阈值: ${ENVIRONMENT.AC_COOLING_THRESHOLD}℃`)
  console.log(`   空调目标温度: ${ENVIRONMENT.AC_TARGET_TEMP}℃`)

  // 每 2 秒更新一次温度
  setInterval(() => {
    const acDevice = deviceStates['ac']
    const wasCooling = environmentState.acCooling

    // 判断空调是否需要制冷
    // 条件：空调开启 + 室温超过制冷阈值
    if (acDevice.on && environmentState.roomTemperature > ENVIRONMENT.AC_COOLING_THRESHOLD) {
      environmentState.acCooling = true
      // 空调制冷：温度下降
      const coolingRate = ENVIRONMENT.TEMP_CHANGE_RATE * 2 // 每 2 秒的变化量
      environmentState.roomTemperature -= coolingRate

      // 如果室温已低于目标温度，停止制冷
      if (environmentState.roomTemperature <= ENVIRONMENT.AC_TARGET_TEMP) {
        environmentState.roomTemperature = ENVIRONMENT.AC_TARGET_TEMP
        environmentState.acCooling = false
      }
    } else {
      environmentState.acCooling = false
      // 自然恢复：温度趋向室外温度
      const recoveryRate = ENVIRONMENT.TEMP_RECOVERY_RATE * 2
      const tempDiff = ENVIRONMENT.OUTDOOR_TEMP - environmentState.roomTemperature
      if (Math.abs(tempDiff) > 0.1) {
        environmentState.roomTemperature += Math.sign(tempDiff) * recoveryRate
      }
    }

    // 限制温度范围
    environmentState.roomTemperature = Math.max(10, Math.min(40, environmentState.roomTemperature))

    // 状态变化时发布
    if (wasCooling !== environmentState.acCooling) {
      console.log(`🌡️  空调制冷状态: ${environmentState.acCooling ? '开启' : '关闭'}`)
      console.log(`   当前室温: ${environmentState.roomTemperature.toFixed(1)}℃`)
      publishRoomTemperature()
    }

    // 每 30 秒发布一次室温状态
    const now = Date.now()
    if (now - environmentState.lastUpdate >= 30000) {
      environmentState.lastUpdate = now
      publishRoomTemperature()
    }
  }, 2000)
}

// ============================================================
//  时间模拟系统
// ============================================================

/** 获取当前模拟时间 */
function getCurrentSimulatedTime() {
  return {
    hour: timeSimulationState.currentHour,
    minute: timeSimulationState.currentMinute,
    second: timeSimulationState.currentSecond,
    dayOfWeek: new Date().getDay(), // 使用真实星期
    timestamp: Date.now()
  }
}

/** 获取时间状态 */
function getTimeState() {
  const time = getCurrentSimulatedTime()
  return {
    hour: time.hour,
    minute: time.minute,
    second: time.second,
    dayOfWeek: time.dayOfWeek,
    paused: timeSimulationState.paused,
    formatted: `${String(time.hour).padStart(2, '0')}:${String(time.minute).padStart(2, '0')}:${String(time.second).padStart(2, '0')}`
  }
}

/** 发布时间状态 */
function publishTimeState() {
  const timeState = getTimeState()

  // 推送到 Web 面板
  broadcastToWeb({
    type: 'time_update',
    data: timeState
  })

  // 发布到 MQTT
  client.publish('home/system/time', JSON.stringify(timeState), { qos: 0 })
}

/** 处理时间设置指令 */
function handleTimeSettingCommand(msgStr) {
  console.log(`\n⏰ 收到时间设置指令: ${msgStr}`)

  let cmd
  try {
    cmd = JSON.parse(msgStr)
  } catch (e) {
    console.log(`   ❌ JSON 解析失败: ${e.message}`)
    return
  }

  // 暂停/恢复
  if (typeof cmd.pause === 'boolean') {
    timeSimulationState.paused = cmd.pause
    console.log(`   ✅ 时间模拟: ${cmd.pause ? '已暂停' : '已恢复'}`)
  }

  // 设置时间
  if (typeof cmd.hour === 'number' && typeof cmd.minute === 'number') {
    timeSimulationState.currentHour = Math.max(0, Math.min(23, cmd.hour))
    timeSimulationState.currentMinute = Math.max(0, Math.min(59, cmd.minute))
    timeSimulationState.currentSecond = 0
    console.log(`   ✅ 时间已设置为: ${timeSimulationState.currentHour}:${String(timeSimulationState.currentMinute).padStart(2, '0')}`)
  }

  // 清除已执行的定时任务记录（允许重新执行）
  if (cmd.resetExecuted) {
    timeSimulationState.executedAutomations.clear()
    console.log(`   ✅ 已清除定时任务执行记录`)
  }

  publishTimeState()
  checkTimeAutomations()
}

/** 启动时间模拟 */
function startTimeSimulation() {
  console.log('⏰ 时间模拟已启动')

  // 每秒更新时间（正常读秒）
  setInterval(() => {
    // 如果暂停，不更新时间
    if (timeSimulationState.paused) {
      return
    }

    // 每秒递增
    timeSimulationState.currentSecond++

    // 进位处理
    if (timeSimulationState.currentSecond >= 60) {
      timeSimulationState.currentSecond = 0
      timeSimulationState.currentMinute++

      // 每分钟检查一次定时任务
      checkTimeAutomations()
    }
    if (timeSimulationState.currentMinute >= 60) {
      timeSimulationState.currentMinute = 0
      timeSimulationState.currentHour++
    }
    if (timeSimulationState.currentHour >= 24) {
      timeSimulationState.currentHour = 0
      // 新的一天，清除已执行记录
      timeSimulationState.executedAutomations.clear()
    }

    // 每秒发布时间状态到 Web 面板
    publishTimeState()
  }, 1000)
}

// ============================================================
//  状态同步系统
// ============================================================

/** 启动自动同步（每 120ms 检查一次） */
function startAutoSync() {
  console.log('🔄 自动同步已启动 (每 120ms)')

  setInterval(() => {
    syncWithApp()
  }, 120)
}

/** 与 APP 同步状态 */
function syncWithApp() {
  const now = Date.now()

  // 遍历所有设备，检查是否需要同步
  DEVICES.forEach(device => {
    const simState = deviceStates[device.id]
    const appState = syncState.appDeviceStates[device.id]

    // 如果没有 APP 状态记录，跳过
    if (!appState) return

    // 比较时间戳，以最后操作为准
    if (appState.lastUpdate > simState.lastUpdate) {
      // APP 的状态更新，同步到模拟器
      console.log(`\n🔄 同步状态 [${device.name}] ← APP`)
      console.log(`   APP 时间: ${new Date(appState.lastUpdate).toLocaleTimeString()}`)
      console.log(`   模拟器时间: ${new Date(simState.lastUpdate).toLocaleTimeString()}`)

      // 更新模拟器状态
      Object.keys(appState).forEach(key => {
        if (key !== 'lastUpdate' && key !== 'lastSource') {
          deviceStates[device.id][key] = appState[key]
        }
      })
      deviceStates[device.id].lastUpdate = appState.lastUpdate
      deviceStates[device.id].lastSource = 'app'

      // 发布更新状态
      publishDeviceState(device)

      // 通知 Web 面板
      broadcastToWeb({
        type: 'state_update',
        data: { id: device.id, name: device.name, ...deviceStates[device.id], timestamp: now }
      })
    }
  })
}

/** 处理来自 APP 的状态同步 */
function handleAppStateSync(topic, msgStr) {
  // 从主题中提取设备 ID
  const parts = topic.split('/')
  const deviceId = parts[2]

  const device = DEVICES.find(d => d.id === deviceId)
  if (!device) {
    console.log(`⚠️  APP 同步: 未知设备 ${deviceId}`)
    return
  }

  console.log(`\n📱 收到 APP 状态 [${device.name}]`)

  let appState
  try {
    appState = JSON.parse(msgStr)
  } catch (e) {
    console.log(`   ❌ JSON 解析失败: ${e.message}`)
    return
  }

  // 添加时间戳
  appState.lastUpdate = Date.now()
  appState.lastSource = 'app'

  // 存储 APP 状态
  syncState.appDeviceStates[deviceId] = appState

  // 立即检查是否需要同步
  syncWithApp()
}

/** 强制与 APP 同步（刷新按钮触发） */
function forceSyncWithApp() {
  console.log('\n🔄 强制同步开始...')

  // 发布当前所有设备状态到 APP
  DEVICES.forEach(device => {
    publishDeviceState(device)
  })

  // 请求 APP 发送当前状态
  client.publish('home/system/sync/request', JSON.stringify({
    action: 'request_state',
    timestamp: Date.now()
  }), { qos: 1 })

  // 通知 Web 面板
  broadcastToWeb({
    type: 'sync_status',
    data: { message: '正在同步...', timestamp: Date.now() }
  })

  console.log('🔄 强制同步完成')
}

// ============================================================
//  设备注册与可扩展性
// ============================================================

/** 处理设备注册 */
function handleDeviceRegistration(deviceInfo, ws) {
  console.log(`\n📝 收到设备注册请求:`)
  console.log(`   设备名称: ${deviceInfo.name}`)
  console.log(`   设备类型: ${deviceInfo.type}`)
  console.log(`   通信协议: ${deviceInfo.protocol}`)

  // 生成设备配置
  const deviceConfig = {
    id: deviceInfo.id,
    name: deviceInfo.name,
    type: deviceInfo.type,
    protocol: deviceInfo.protocol,
    stateTopic: `home/device/${deviceInfo.id}/state`,
    commandTopic: `home/device/${deviceInfo.id}/command`,
    appStateTopic: `home/device/${deviceInfo.id}/state/app`,
    capabilities: getDeviceCapabilities(deviceInfo.type),
    registeredAt: Date.now(),
    status: 'online'
  }

  console.log(`\n   ✅ 设备注册成功:`)
  console.log(`   - 状态主题: ${deviceConfig.stateTopic}`)
  console.log(`   - 指令主题: ${deviceConfig.commandTopic}`)
  console.log(`   - 设备能力: ${deviceConfig.capabilities.join(', ')}`)

  // 通知 Web 面板注册成功
  if (ws) {
    ws.send(JSON.stringify({
      type: 'device_registered',
      data: deviceConfig
    }))
  }

  // 广播设备注册事件
  broadcastToWeb({
    type: 'device_registered',
    data: deviceConfig
  })
}

/** 获取设备能力列表 */
function getDeviceCapabilities(type) {
  const capabilities = {
    'light': ['on', 'off', 'set_brightness'],
    'ac': ['on', 'off', 'set_temperature', 'set_mode'],
    'curtain': ['on', 'off', 'set_level'],
    'appliance': ['on', 'off'],
    'lock': ['lock', 'unlock']
  }
  return capabilities[type] || ['on', 'off']
}

/** 获取协议信息 */
function getProtocolInfo(protocol) {
  const protocols = {
    'MQTT': {
      version: '3.1.1',
      port: 1883,
      securePort: 8883,
      encryption: 'TLS 1.3',
      qos: '支持 QoS 0/1/2'
    },
    'CoAP': {
      version: 'RFC 7252',
      port: 5683,
      securePort: 5684,
      encryption: 'DTLS',
      qos: '确认/非确认'
    },
    'Zigbee': {
      version: '3.0',
      port: 'N/A',
      securePort: 'N/A',
      encryption: 'AES-128-CCM',
      qos: '网状网络'
    },
    'WiFi': {
      version: '802.11ac',
      port: 80,
      securePort: 443,
      encryption: 'WPA3',
      qos: 'TCP/UDP'
    }
  }
  return protocols[protocol] || protocols['MQTT']
}

/** 检查定时自动化任务 */
function checkTimeAutomations() {
  const time = getCurrentSimulatedTime()
  const currentTimeKey = `${time.hour}:${time.minute}`
  const currentDay = time.dayOfWeek

  AUTOMATIONS.forEach(automation => {
    if (!automation.enabled) return
    if (automation.trigger.type !== 'time') return

    const trigger = automation.trigger
    const triggerTimeKey = `${trigger.hour}:${trigger.minute}`
    const automationKey = `${automation.id}_${time.hour}_${time.minute}`

    // 检查时间匹配
    if (currentTimeKey !== triggerTimeKey) return

    // 检查星期匹配
    if (!trigger.days.includes(currentDay)) return

    // 检查是否已执行（避免重复执行）
    if (timeSimulationState.executedAutomations.has(automationKey)) return

    // 执行自动化
    console.log(`\n🤖 执行定时自动化: ${automation.name}`)
    console.log(`   触发时间: ${triggerTimeKey}`)
    executeAutomationActions(automation)

    // 记录已执行
    timeSimulationState.executedAutomations.add(automationKey)
  })
}

/** 执行自动化动作 */
function executeAutomationActions(automation) {
  const now = Date.now()

  automation.actions.forEach((action, index) => {
    const device = DEVICES.find(d => d.id === action.deviceId)
    if (!device) {
      console.log(`   ⚠️  未找到设备: ${action.deviceId}`)
      return
    }

    console.log(`   ${index + 1}. ${device.name} → ${action.command.action}${action.command.value !== undefined ? ' ' + action.command.value : ''}`)

    // 延迟执行，避免消息风暴
    setTimeout(() => {
      // 更新时间戳和来源
      deviceStates[device.id].lastUpdate = now
      deviceStates[device.id].lastSource = 'simulator'

      handleCommand(device, action.command)
    }, index * 500)
  })
}

/** 获取自动化状态 */
function getAutomationsState() {
  return AUTOMATIONS.map(auto => ({
    id: auto.id,
    name: auto.name,
    description: auto.description,
    enabled: auto.enabled,
    trigger: auto.trigger,
    actionsCount: auto.actions.length
  }))
}

/** 处理自动化控制指令 */
function handleAutomationCommand(msgStr) {
  console.log(`\n🤖 收到自动化控制指令: ${msgStr}`)

  let cmd
  try {
    cmd = JSON.parse(msgStr)
  } catch (e) {
    console.log(`   ❌ JSON 解析失败: ${e.message}`)
    return
  }

  // 触发场景
  if (cmd.sceneName) {
    const automation = AUTOMATIONS.find(a => a.trigger.type === 'scene' && a.trigger.sceneName === cmd.sceneName)
    if (automation) {
      console.log(`   ✅ 触发场景: ${automation.name}`)
      executeAutomationActions(automation)

      // 通知 Web 面板
      broadcastToWeb({
        type: 'automation_triggered',
        data: { id: automation.id, name: automation.name }
      })
    } else {
      console.log(`   ⚠️  未找到场景: ${cmd.sceneName}`)
    }
  }

  // 启用/禁用自动化
  if (cmd.automationId && typeof cmd.enabled === 'boolean') {
    const automation = AUTOMATIONS.find(a => a.id === cmd.automationId)
    if (automation) {
      automation.enabled = cmd.enabled
      console.log(`   ✅ 自动化 "${automation.name}": ${cmd.enabled ? '启用' : '禁用'}`)

      // 通知 Web 面板
      broadcastToWeb({
        type: 'automations_update',
        data: getAutomationsState()
      })
    }
  }

  // 手动执行自动化
  if (cmd.automationId && cmd.action === 'execute') {
    const automation = AUTOMATIONS.find(a => a.id === cmd.automationId)
    if (automation) {
      console.log(`   ✅ 手动执行: ${automation.name}`)
      executeAutomationActions(automation)
    }
  }
}

// ============================================================
//  10. 定时心跳
// ============================================================

setInterval(() => {
  publishHeartbeat()
}, INTERVALS.HEARTBEAT)

// ============================================================
//  11. 启动 Web 服务
// ============================================================

server.listen(WEB_PORT, () => {
  console.log(`🌐 可视化面板已启动: http://localhost:${WEB_PORT}`)
  console.log('')
})

// ============================================================
//  12. 优雅退出
// ============================================================

function shutdown() {
  console.log('\n🛑 正在关闭模拟器...')

  // 发布所有设备离线状态
  DEVICES.forEach(device => {
    const payload = JSON.stringify({
      id: device.id, name: device.name, online: false, timestamp: Date.now()
    })
    client.publish(device.stateTopic, payload, { qos: 0 })
  })

  // 关闭 WebSocket 服务
  wss.close()

  // 关闭 HTTP 服务
  server.close()

  client.end(false, {}, () => {
    console.log('👋 模拟器已退出')
    process.exit(0)
  })
}

process.on('SIGINT', shutdown)
process.on('SIGTERM', shutdown)
process.on('SIGHUP', shutdown)
