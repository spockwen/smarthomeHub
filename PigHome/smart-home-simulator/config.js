// ============================================================
// 设备配置 - 定义所有模拟设备的元数据和初始状态
// ============================================================

const DEVICES = [
  {
    id: 'living_room_light',
    name: '客厅主灯',
    icon: '💡',
    room: '客厅',
    type: 'light',
    stateTopic: 'home/device/living_room_light/state',
    commandTopic: 'home/device/living_room_light/command',
    initialState: {
      online: true,
      on: true,
      brightness: 100
    }
  },
  {
    id: 'study_light',
    name: '书房灯',
    icon: '💡',
    room: '书房',
    type: 'light',
    stateTopic: 'home/device/study_light/state',
    commandTopic: 'home/device/study_light/command',
    initialState: {
      online: true,
      on: true,
      brightness: 100
    }
  },
  {
    id: 'range_hood',
    name: '油烟机',
    icon: '🍳',
    room: '厨房',
    type: 'appliance',
    stateTopic: 'home/device/range_hood/state',
    commandTopic: 'home/device/range_hood/command',
    initialState: {
      online: true,
      on: true
    }
  },
  {
    id: 'air_purifier',
    name: '空气净化器',
    icon: '💨',
    room: '客厅',
    type: 'appliance',
    stateTopic: 'home/device/air_purifier/state',
    commandTopic: 'home/device/air_purifier/command',
    initialState: {
      online: true,
      on: true,
      aqi: 12
    }
  },
  {
    id: 'ac',
    name: '空调',
    icon: '❄️',
    room: '客厅',
    type: 'ac',
    stateTopic: 'home/device/ac/state',
    commandTopic: 'home/device/ac/command',
    initialState: {
      online: true,
      on: true,
      temperature: 24,
      mode: 'cool'
    }
  },
  {
    id: 'curtain',
    name: '电动窗帘',
    icon: '🪟',
    room: '主卧',
    type: 'curtain',
    stateTopic: 'home/device/curtain/state',
    commandTopic: 'home/device/curtain/command',
    initialState: {
      online: true,
      on: true,
      level: 100
    }
  },
  {
    id: 'projector',
    name: '投影仪',
    icon: '🎥',
    room: '客厅',
    type: 'appliance',
    stateTopic: 'home/device/projector/state',
    commandTopic: 'home/device/projector/command',
    initialState: {
      online: true,
      on: false
    }
  },
  {
    id: 'door_lock',
    name: '智能门锁',
    icon: '🔒',
    room: '客厅',
    type: 'lock',
    stateTopic: 'home/device/door_lock/state',
    commandTopic: 'home/device/door_lock/command',
    initialState: {
      online: true,
      locked: true
    }
  }
]

// 系统主题
const TOPICS = {
  DEVICE_LIST: 'home/devices/list',
  HEARTBEAT: 'home/system/heartbeat',
  ROOM_TEMPERATURE: 'home/environment/temperature'
}

// 室内环境配置
const ENVIRONMENT = {
  INITIAL_ROOM_TEMP: 26,        // 初始室温 (℃)
  TEMP_CHANGE_RATE: 0.5,        // 温度变化速率 (℃/秒，空调制冷时)
  TEMP_RECOVERY_RATE: 0.1,      // 温度自然恢复速率 (℃/秒，趋向环境温度)
  OUTDOOR_TEMP: 32,             // 室外温度 (℃，影响自然恢复)
  AC_COOLING_THRESHOLD: 26,     // 空调自动制冷阈值 (℃) - 室温超过此温度时触发制冷
  AC_TARGET_TEMP: 24            // 空调目标温度 (℃) - 制冷时的目标温度
}

// 时间模拟配置
const TIME_SIMULATION = {
  INITIAL_HOUR: 8,              // 初始小时 (0-23)
  INITIAL_MINUTE: 0             // 初始分钟 (0-59)
}

// 自动化场景配置
const AUTOMATIONS = [
  {
    id: 'morning_curtain',
    name: '早晨自动开窗帘',
    description: '每天 7:30 自动打开窗帘到 80%',
    enabled: true,
    trigger: {
      type: 'time',
      hour: 7,
      minute: 30,
      days: [0, 1, 2, 3, 4, 5, 6]  // 0=周日, 1-6=周一到周六
    },
    actions: [
      { deviceId: 'curtain', command: { action: 'set_level', value: 80 } }
    ]
  },
  {
    id: 'home_mode',
    name: '回家模式',
    description: '触发回家模式时自动调节空调到 26°',
    enabled: true,
    trigger: {
      type: 'scene',
      sceneName: 'scene_home'
    },
    actions: [
      { deviceId: 'ac', command: { action: 'set_temperature', value: 26 } },
      { deviceId: 'living_room_light', command: { action: 'on' } },
      { deviceId: 'study_light', command: { action: 'on' } },
      { deviceId: 'air_purifier', command: { action: 'on' } }
    ]
  },
  {
    id: 'leave_mode',
    name: '离家模式',
    description: '触发离家模式时关闭所有灯光',
    enabled: true,
    trigger: {
      type: 'scene',
      sceneName: 'scene_leave'
    },
    actions: [
      { deviceId: 'living_room_light', command: { action: 'off' } },
      { deviceId: 'study_light', command: { action: 'off' } },
      { deviceId: 'range_hood', command: { action: 'off' } },
      { deviceId: 'air_purifier', command: { action: 'off' } },
      { deviceId: 'ac', command: { action: 'off' } },
      { deviceId: 'projector', command: { action: 'off' } },
      { deviceId: 'curtain', command: { action: 'set_level', value: 0 } }
    ]
  },
  {
    id: 'movie_mode',
    name: '观影模式',
    description: '触发观影模式时调暗灯光、关闭窗帘、打开投影仪',
    enabled: true,
    trigger: {
      type: 'scene',
      sceneName: 'scene_movie'
    },
    actions: [
      { deviceId: 'living_room_light', command: { action: 'set_brightness', value: 20 } },
      { deviceId: 'study_light', command: { action: 'off' } },
      { deviceId: 'curtain', command: { action: 'set_level', value: 0 } },
      { deviceId: 'projector', command: { action: 'on' } }
    ]
  },
  {
    id: 'night_mode',
    name: '晚安模式',
    description: '每晚 23:00 关闭所有灯光，锁定门锁',
    enabled: true,
    trigger: {
      type: 'time',
      hour: 23,
      minute: 0,
      days: [0, 1, 2, 3, 4, 5, 6]
    },
    actions: [
      { deviceId: 'living_room_light', command: { action: 'off' } },
      { deviceId: 'study_light', command: { action: 'off' } },
      { deviceId: 'projector', command: { action: 'off' } },
      { deviceId: 'door_lock', command: { action: 'off' } }
    ]
  }
]

// 时间间隔（毫秒）
const INTERVALS = {
  HEARTBEAT: 30000,         // 心跳：30秒
  STATE_PUBLISH: 1000,      // 状态发布后延迟：1秒
  STARTUP_DELAY: 2000       // 启动后延迟：2秒
}

module.exports = { DEVICES, TOPICS, INTERVALS, ENVIRONMENT, TIME_SIMULATION, AUTOMATIONS }
