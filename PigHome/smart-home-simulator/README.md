# 智能家居设备模拟器

通过 MQTT 协议模拟 8 个智能设备，与鸿蒙 APP 进行双向通信。内置 Web 可视化面板，实时展示设备状态。

## 模拟设备列表

| 设备ID | 设备名 | 房间 | 类型 |
|---|---|---|---|
| living_room_light | 客厅主灯 | 客厅 | 灯光 |
| study_light | 书房灯 | 书房 | 灯光 |
| range_hood | 油烟机 | 厨房 | 电器 |
| air_purifier | 空气净化器 | 客厅 | 电器 |
| ac | 空调 | 客厅 | 空调 |
| curtain | 电动窗帘 | 主卧 | 窗帘 |
| projector | 投影仪 | 客厅 | 电器 |
| door_lock | 智能门锁 | 客厅 | 门锁 |

## 前置条件

1. Docker Desktop 正在运行
2. EMQX 容器已启动，端口 1883/18083 已映射
3. Node.js 已安装（v16+）

## 安装与运行

```bash
# 安装依赖
npm install

# 启动模拟器
npm start
```

启动后：
- **MQTT 模拟器** 连接到 EMQX（127.0.0.1:1883）
- **Web 可视化面板** 启动在 http://localhost:3000

## Web 可视化面板

浏览器打开 `http://localhost:3000`，可以看到：

- 🏠 **设备卡片** — 按房间分组，显示所有 8 个设备的实时状态
- 💡 **灯光控制** — 显示亮度进度条，可点击开关
- ❄️ **空调控制** — 显示温度，带 +/- 调节按钮
- 🪟 **窗帘控制** — 显示开合度进度条
- 🔒 **门锁状态** — 锁定/解锁指示
- 🎬 **场景模式** — 回家/离家一键切换
- 📋 **消息日志** — 可折叠的 MQTT 消息记录

### 交互链路

```
浏览器页面 ←WebSocket→ simulator.js ←MQTT→ EMQX ←MQTT→ 鸿蒙APP
```

- 在网页点击设备开关 → 通过 WebSocket 发送到模拟器 → 模拟器发布 MQTT 指令 → 鸿蒙 APP 收到状态更新
- 在鸿蒙 APP 操作设备 → MQTT 指令到达模拟器 → WebSocket 推送到网页 → 页面实时刷新

## MQTT 主题设计

| 主题 | 方向 | 说明 |
|---|---|---|
| `home/device/{id}/state` | 模拟器 → APP | 设备状态上报 |
| `home/device/{id}/command` | APP → 模拟器 | APP 下发控制指令 |
| `home/devices/list` | 模拟器 → APP | 设备列表广播 |
| `home/system/heartbeat` | 双向 | 心跳保活 |

## 支持的指令

| action | 说明 | 参数 |
|---|---|---|
| `on` | 开启设备 | - |
| `off` | 关闭设备 | - |
| `toggle` | 切换开关 | - |
| `set_brightness` | 设置亮度 | `value`: 0-100 |
| `set_temperature` | 设置温度 | `value`: 16-30 |
| `set_level` | 设置窗帘开合度 | `value`: 0-100 |
| `scene_home` | 回家模式 | - |
| `scene_leave` | 离家模式 | - |
| `query` | 查询状态 | - |

## 环境变量

在 `.env` 文件中配置：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `MQTT_BROKER_URL` | `mqtt://127.0.0.1:1883` | EMQX 地址 |
| `MQTT_USERNAME` | `admin` | MQTT 用户名 |
| `MQTT_PASSWORD` | - | MQTT 密码 |
| `MQTT_CLIENT_ID` | `simulator_node_01` | 客户端ID |
| `WEB_PORT` | `3000` | Web 面板端口 |

## 调试

- EMQX 管理面板: http://localhost:18083 （admin / 密码见 .env）
- 使用 MQTT Explorer 连接 127.0.0.1:1883 查看消息流
- Web 面板底部有实时消息日志
