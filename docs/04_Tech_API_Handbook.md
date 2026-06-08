# Phase 4：技术接入手册（API 清单与调用指南）

> **本文档版本：** v1.0  
> **编制日期：** 2026-06-04  
> **适配系统：** HarmonyOS 4.0+（NEXT / Dev Eco Studio 5.0+）  
> **所属项目：** SmartHome AIHub 鸿蒙全页面重构设计

---

## 📋 目录

1. [图形渲染 API](#1-图形渲染-api)
2. [动画引擎 API](#2-动画引擎-api)
3. [手势识别 API](#3-手势识别-api)
4. [设备通信 API](#4-设备通信-api)
5. [分布式能力 API](#5-分布式能力-api)
6. [UI 组件库 API](#6-ui-组件库-api)
7. [安全与权限 API](#7-安全与权限-api)
8. [API 异常处理汇总](#8-api-异常处理汇总)

---

## 1. 图形渲染 API

### 1.1 阴影与光晕（ohos.graphics.shadow）

**接口名称：** `shadow(ShadowOptions)` 组件方法

**所属模块：** ArkUI 内置（`@ohos.app.ability.Window` 窗口管理补充）

**适用场景：** 沉浸光感控件（卡片、按钮、开关滑块）的外发光层

**调用方式：**

```typescript
// 在 Column / Row / Stack / Button 等容器组件上直接调用
Component()
  .shadow({
    radius: 20,              // 模糊半径（0-100vp）
    color: '#33007DFF',       // 阴影颜色（支持 rgba）
    type: ShadowType.BLUR,    // ShadowType.COLOR | ShadowType.BLUR
    offsetX: 0,
    offsetY: 4
  })
```

**核心参数说明：**

| 参数 | 类型 | 取值范围 | 默认值 | 说明 |
|------|------|---------|--------|------|
| `radius` | number | 0-100vp | 0 | 模糊半径，越大越柔和 |
| `color` | string | rgba / hex | `#000000` | 阴影颜色，建议使用半透明色 |
| `type` | ShadowType | BLUR / COLOR | BLUR | BLUR=面积与 radius 成正比，COLOR=固定面积 |
| `offsetX` | number | -∞~+∞ | 0 | X 轴偏移 |
| `offsetY` | number | -∞~+∞ | 0 | Y 轴偏移（正值向下） |

**前置条件：** 无特殊要求，所有 ArkUI 容器组件均支持

**异常处理：** `radius: 0` 时阴影不渲染，视觉上等同于无阴影

---

### 1.2 高斯模糊

**接口名称：** ArkUI 内置模糊装饰（通过 Stack 叠加实现）

**实现方式：** 不建议对主内容层使用 blur，对性能影响大。采用 `Stack` 叠加半透明色层来模拟光感效果

```typescript
// 模拟光感叠加层（推荐）
Stack() {
  // 底层实际内容
  Rect().fill('#007DFF')

  // 叠加半透明模糊层
  Rect()
    .fill('rgba(0, 165, 255, 0.3)')
    .blur(15) // 仅在此层使用模糊，不影响主内容
}
```

**模糊性能优化建议：**

| 建议 | 说明 |
|------|------|
| 模糊面积不超过 200×200vp | 大面积模糊严重消耗 GPU |
| 避免在列表滚动中实时渲染模糊 | 滚动时禁用模糊，静止后恢复 |
| 使用 `clip` 裁剪模糊边界 | 避免模糊溢出到相邻组件 |

---

### 1.3 渐变色（LinearGradient / RadialGradient）

**接口名称：** ArkUI 内置 `LinearGradient` / `RadialGradient`

**适用场景：** 滑轨填充、开关 Track、情景模式按钮激活态、设备状态指示

**LinearGradient 调用方式：**

```typescript
new LinearGradient({
  direction: GradientDirection.Left,  // 渐变方向
  // Left / Right / Top / Bottom / LeftTop / LeftBottom / RightTop / RightBottom
  colors: [
    ['#007DFF', 0],     // [颜色, 起始位置（0-1）]
    ['#00A5FF', 0.5],
    ['#007DFF', 1]
  ]
})
```

**RadialGradient 调用方式：**

```typescript
new RadialGradient({
  center: { x: '50%', y: '50%' },  // 圆心位置
  radius: '50%',                   // 半径（相对于组件尺寸）
  colors: [
    ['#007DFF', 0],
    ['#00A5FF', 1]
  ]
})
```

**参数说明：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `direction` | GradientDirection | 线性渐变方向 |
| `center` | `{x, y}` | 径向渐变圆心 |
| `radius` | string / number | 径向渐变半径 |
| `colors` | `Array<[color, stop]>` | 颜色数组 + 停止位置 |

---

### 1.4 图形渲染 API 汇总表

| API | 模块 | 适用场景 | 性能影响 |
|-----|------|---------|---------|
| `shadow()` | ArkUI 内置 | 卡片/按钮/滑块光晕 | 低（GPU 合成） |
| `LinearGradient` | ArkUI 内置 | 滑轨渐变、Track 渐变 | 低 |
| `RadialGradient` | ArkUI 内置 | 环形光效、圆形按钮 | 中（圆形计算） |
| `blur()` | `@ohos.effect` | 背景模糊层 | **高（慎用）** |
| `backgroundColor` | ArkUI 内置 | 纯色背景 | 极低 |
| `opacity` | ArkUI 内置 | 透明度叠加 | 极低 |
| `saturation` | ArkUI 内置 | 灰度化（离线态） | 极低 |

---

## 2. 动画引擎 API

### 2.1 属性动画 animateTo()

**接口名称：** `animateTo(AnimateToOptions, () => void)`

**所属模块：** ArkUI 内置 `api.animateTo`

**适用场景：** 状态切换隐式动画、场景激活脉冲、设备状态变化反馈

**调用方式：**

```typescript
animateTo({
  duration: 200,                    // 动画时长（毫秒）
  curve: Curve.EaseOut,             // 动画曲线
  delay?: 0,                        // 延迟（毫秒）
  iterations?: 1,                   // 重复次数
  playMode?: PlayMode.Normal,       // 播放模式
}, () => {
  // 动画终点状态变更
  this.scale = 1.1;
  this.glowOpacity = 0.5;
})
```

**核心参数说明：**

| 参数 | 类型 | 取值范围 | 默认值 | 说明 |
|------|------|---------|--------|------|
| `duration` | number | 0-10000ms | 300 | 动画时长 |
| `curve` | Curve | EaseOut / EaseIn / FastOutSlowIn / Linear / Spring 等 | EaseOut | 动画曲线 |
| `delay` | number | 0-10000ms | 0 | 延迟执行 |
| `iterations` | number | 1-∞ | 1 | 重复次数（-1 表示无限循环） |
| `playMode` | PlayMode | Normal / Reverse / Alternate / AlternateReverse | Normal | 播放模式 |

**前置条件：** 无特殊要求

**异常处理：** 页面销毁时正在执行的动画自动中止，不会崩溃

---

### 2.2 弹性动画（Spring Motion）

**接口名称：** `Curve.Spring()` ArkUI 内置弹性曲线

**适用场景：** 滑块拖动释放回弹、卡片点击回弹、跨设备拖拽释放

```typescript
animateTo({
  duration: 400,
  curve: Curve.Spring({
    response: 0.5,      // 弹簧响应时间（秒）
    dampingFraction: 0.8, // 阻尼系数（0=完全弹性，1=无弹性）
    // 建议范围：0.7-0.9，智能家居场景偏硬朗
    spacing: 0
  })
}, () => {
  this.thumbX = this.targetX;
})
```

**Spring 参数说明：**

| 参数 | 类型 | 推荐值 | 说明 |
|------|------|--------|------|
| `response` | number | 0.3-0.8s | 弹簧响应时间，越小越快 |
| `dampingFraction` | number | 0.7-0.9 | 阻尼系数，越小越弹 |
| `spacing` | number | 0 | 间距（一般用 0） |

---

### 2.3 组件级动画 animation()

**接口名称：** `.animation(AnimationOptions)` 组件方法

**适用场景：** 持续性动画（如呼吸光效）、组件状态变更自动触发的动画

```typescript
Column()
  .animation({
    duration: 200,
    curve: Curve.EaseOut,
    delay: 0,
    iterations: 1,
    playMode: PlayMode.Normal
  })
  .scale({ x: this.isPressed ? 0.97 : 1 })
  // isPressed 变化时自动触发动画
```

**与 animateTo 的区别：**

| 维度 | `animateTo` | `animation()` |
|------|-------------|---------------|
| 触发方式 | 主动调用闭包 | 属性变化自动触发 |
| 适用场景 | 复杂动画编排 | 简单状态切换动画 |
| 控制粒度 | 精确控制动画序列 | 单属性动画 |
| 性能 | 略优（闭包内执行） | 声明式，框架优化 |

---

### 2.4 页面转场动画

**接口名称：** `router.pushUrl()` / `router.pop()` 的 animation 参数

**调用方式：**

```typescript
router.pushUrl({
  url: 'pages/DeviceDetail',
  params: { deviceId: this.deviceId }
}, {
  animation: {
    type: router.RouterAnimation.Push,  // Push / Pop / Replace / None
    duration: 300,
    curve: Curve.FastOutSlowIn,
    delay?: 0,
    pageIn?: 0.5,    // 入场动画起点 opacity
    pageOut?: 1      // 出场动画终点 opacity
  }
});
```

**RouterAnimation 类型：**

| 类型 | 效果 |
|------|------|
| `Push` | 从右向左滑入 |
| `Pop` | 从左向右滑出 |
| `Replace` | 渐隐替换 |
| `None` | 无动画 |

---

## 3. 手势识别 API

### 3.1 手势 API 总览

| 手势 | API | 关键参数 | 返回值/回调 |
|------|-----|---------|------------|
| 点击 | `TapGesture` | `fingers`, `distance` | `onAction` |
| 长按 | `LongPressGesture` | `fingers`, `duration` | `onAction` |
| 双击 | `DoubleTapGesture` | `fingers` | `onAction` |
| 滑动 | `PanGesture` | `direction`, `distance`, `fingers` | `onActionStart/Update/End` |
| 捏合 | `PinchGesture` | `fingers` | `onActionStart/Update/End` |
| 拖拽 | `DragGesture` | — | `onActionStart/Update/End` |
| 旋转 | `RotationGesture` | `fingers` | `onActionStart/Update/End` |

### 3.2 PanGesture 滑动完整示例

```typescript
.gesture(
  PanGesture()
    .onActionStart((event: GestureEvent) => {
      // 手指按下滑轨瞬间
      this.isSliding = true;
      this.startX = event.localX;
    })
    .onActionUpdate((event: GestureEvent) => {
      // 拖动过程中（每帧）
      const deltaX = event.localX - this.startX;
      const newPercent = Math.max(0, Math.min(1,
        (this.currentPercent * this.trackWidth + deltaX) / this.trackWidth
      ));
      this.value = Math.floor(newPercent * (this.max - this.min) + this.min);
      this.currentPercent = newPercent;
    })
    .onActionEnd((event: GestureEvent) => {
      // 手指抬起
      this.isSliding = false;
      this.syncToDevice(this.value);
    })
)
```

**GestureEvent 关键属性：**

| 属性 | 类型 | 说明 |
|------|------|------|
| `localX` | number | 相对于组件内部的 X 坐标 |
| `localY` | number | 相对于组件内部的 Y 坐标 |
| `globalX` | number | 相对于屏幕的 X 坐标 |
| `globalY` | number | 相对于屏幕的 Y 坐标 |
| `timestamp` | number | 事件时间戳（毫秒） |

### 3.3 DragEvent 拖拽 API

**拖拽源设置（onDragStart）：**

```typescript
.onDragStart((event: DragEvent) => {
  // 设置携带数据（JSON 字符串）
  event.setData({
    deviceId: this.device.id,
    deviceType: this.device.type,
    action: JSON.stringify({ command: 'turnOn', params: {} })
  });

  // 设置跨设备流转目标
  event.setDragDpid('SAME_NETWORK'); // 同网络可信设备
  // 或指定设备：event.setDragDpid(deviceId);

  // 设置拖拽预览区域
  event.setPreviewRect({
    x: event.localX - 50,
    y: event.localY - 50,
    w: 100,
    h: 100
  });
})
```

**拖拽目标设置（onDrop / onDragEnter / onDragLeave）：**

```typescript
.onDrop((event: DragEvent) => {
  const data = event.getData();
  const deviceId = data['deviceId'];
  const action = JSON.parse(data['action']);
  // 处理放置逻辑
})
.onDragEnter((event: DragEvent) => {
  // 拖拽进入高亮
  this.isDropTargetActive = true;
})
.onDragLeave((event: DragEvent) => {
  // 拖拽离开
  this.isDropTargetActive = false;
})
```

**DragEvent 关键方法：**

| 方法 | 返回值 | 说明 |
|------|--------|------|
| `getData()` | object | 获取拖拽数据 |
| `getDataString()` | string | 获取字符串数据 |
| `setData(data)` | void | 设置拖拽数据 |
| `setDragDpid(target)` | void | 设置流转目标 |
| `getResult()` | number | 0=成功，-1=失败 |
| `setPreviewRect(rect)` | void | 设置预览区域 |

---

## 4. 设备通信 API

### 4.1 设备发现与连接

**接口名称：** `deviceManager.bindDevice()` / `deviceManager.getTrustedDeviceList()`

**所属模块：** `@ohos.distributedhardware.deviceManager`

**调用方式：**

```typescript
import deviceManager from '@ohos.distributedhardware.deviceManager';

// 初始化设备管理器
let dmInstance: deviceManager.DeviceManager;
deviceManager.createDeviceManager('com.smarthome.aihub', (err, dm) => {
  if (!err) {
    this.dmInstance = dm;
  }
});

// 获取可信设备列表
dmInstance.getTrustedDeviceList((err, list) => {
  if (!err) {
    list.forEach((device) => {
      console.info(`设备: ${device.deviceName}, ID: ${device.deviceId}`);
    });
  }
});

// 检查设备在线状态
dmInstance.checkDeviceManagerStatus((err, status) => {
  if (!err) {
    this.isDeviceManagerReady = status === 0;
  }
});
```

**前置条件：**

1. 在 `module.json5` 中申请权限 `ohos.permission.DISTRIBUTED_DEVICE_STATE_ACCESS`
2. 调用前确保设备间已完成配对（在"设备共享"中确认）
3. 设备需在同一局域网内或华为智能家居生态局域网内

**异常处理：**

| 错误码 | 说明 | 处理方案 |
|--------|------|----------|
| `-1` | 设备未发现 | 显示"正在搜索设备..."，自动重试 3 次，间隔 2 秒 |
| `-2` | 设备离线 | 显示离线提示，引导用户检查网络 |
| `-3` | 绑定超时（30s） | 超时提示，提供"重新搜索"按钮 |
| `-100` | 权限不足 | 引导用户前往设置开启权限 |

---

### 4.2 设备控制指令下发

**接口名称：** `preferentiaManager.sendCommand()`

**所属模块：** `@ohos.distributedhardware.preferentiaManager`

**调用方式：**

```typescript
import preferentiaManager from '@ohos.distributedhardware.preferentiaManager';

// 发送设备控制指令
let command = {
  deviceId: 'light_001',           // 目标设备 ID
  command: 'setPower',            // 命令名称
  params: {
    state: 1,                     // 0=关，1=开
    brightness: 80,                // 亮度 0-100
    colorTemp: 4000                // 色温 2700-6500
  },
  transType: 1,                   // 传输类型：1=可靠传输，0=快速传输
  priority: 1,                     // 优先级：1-10
  timeout: 5000                   // 超时时间（毫秒）
};

preferentiaManager.sendCommand(command)
  .then((result) => {
    // 指令发送成功
    console.info(`指令发送成功: ${JSON.stringify(result)}`);
    this.deviceState = 'on';
    promptAction.showToast({ message: '已开启' });
  })
  .catch((err) => {
    // 指令发送失败
    console.error(`指令发送失败: ${err.code} - ${err.message}`);
    this.deviceState = 'off';
    promptAction.showToast({ message: '操作失败，请检查设备连接' });
    // 回退 UI 状态
    this.revertUIState();
  });
```

**Command 结构说明：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `deviceId` | string | 是 | 目标设备唯一标识 |
| `command` | string | 是 | 命令名称（设备端定义） |
| `params` | object | 否 | 命令参数 |
| `transType` | number | 否 | 1=可靠传输（保证送达），0=快速传输 |
| `priority` | number | 否 | 优先级 1-10，数值越大优先级越高 |
| `timeout` | number | 否 | 超时时间，默认 5000ms |

**前置条件：**

1. 设备已完成配对绑定
2. 设备在线（下发前建议先 checkDeviceOnline）
3. 应用已获取 `ohos.permission.DISTRIBUTED_DEVICE_STATE_ACCESS` 权限

---

### 4.3 设备状态实时同步

**接口名称：** `deviceStateChange` 事件订阅

**调用方式：**

```typescript
// 订阅设备状态变更（推荐在 EntryAbility onCreate 中初始化）
dmInstance.on('deviceStateChange', (data) => {
  if (data.deviceId === this.targetDeviceId) {
    switch (data.type) {
      case 0: // 设备上线
        this.deviceOnline = true;
        break;
      case 1: // 设备下线
        this.deviceOnline = false;
        break;
      case 2: // 设备状态变更
        this.parseDeviceState(data.params);
        break;
    }
    // 通知 UI 刷新
    this.notifyStateChange();
  }
});

// 取消订阅（aboutToDisappear 中调用）
aboutToDisappear() {
  dmInstance.off('deviceStateChange');
}
```

**deviceStateChange 数据结构：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `deviceId` | string | 设备 ID |
| `type` | number | 0=上线，1=下线，2=状态变更 |
| `params` | object | 设备状态数据（设备端定义） |

---

## 5. 分布式能力 API

### 5.1 分布式数据管理（KVStore）

**接口名称：** `distributedKVStore.createKVManager()` / `kvStore.put()` / `kvStore.get()`

**所属模块：** `@ohos.data.distributedKVStore`

**适用场景：** 设备状态跨设备同步、用户偏好设置同步、场景数据同步

**调用方式：**

```typescript
import distributedKVStore from '@ohos.data.distributedKVStore';

// 创建 KVManager
const kvManager = distributedKVStore.createKVManager({
  context: this.context,
  bundleName: 'com.smarthome.aihub'
});

// 获取或创建 KVStore
kvManager.getKVStore('device_state_store', {
  createIfMissing: true,
  syncInterval: 300 // 同步间隔（分钟）
}, (err, kvStore) => {
  if (err) {
    console.error(`创建 KVStore 失败: ${err}`);
    return;
  }

  // 写入数据
  kvStore.put('scene_mode', 'home', (err) => {
    if (!err) {
      console.info('场景模式已保存');

      // 同步到其他设备
      kvStore.sync(
        'SYNCHRONIZE_RETAIN', // 保留本地优先数据
        distributedKVStore.SyncMode.SYNC_RETAIN
      );
    }
  });

  // 读取数据
  kvStore.get('scene_mode', (err, value) => {
    if (!err) {
      this.sceneMode = value;
    }
  });

  // 订阅数据变更（实时同步）
  kvStore.on('syncComplete', (data) => {
    console.info('数据同步完成');
    this.loadLatestData();
  });
});
```

**KVStore 数据类型支持：**

| 类型 | 说明 |
|------|------|
| `string` | 字符串 |
| `number` | 数值 |
| `boolean` | 布尔值 |
| `number[]` | 数值数组 |
| `string[]` | 字符串数组 |
| `object`（JSON） | 通过 JSON.stringify/parse 存储对象 |

**前置条件：**

1. 设备已完成华为账号登录并开启"设备协同"
2. 应用已申请 `ohos.permission.DISTRIBUTED_DATASYNC` 权限
3. KVStore 名称全局唯一（跨应用需加包名前缀）

---

### 5.2 want-agent 跨设备启动

**接口名称：** `wantAgent.getWantAgent()` / `wantAgent.startAbility()`

**所属模块：** `@ohos.wantAgent`

**适用场景：** 手机一键流转场景到智慧屏、跨设备唤醒应用

**调用方式：**

```typescript
import wantAgent from '@ohos.wantAgent';

// 构建 Want
let want = {
  deviceId: targetDeviceId,        // 目标设备 ID
  bundleName: 'com.smarthome.aihub', // 目标应用包名
  abilityName: 'EntryAbility',       // 入口 Ability
  parameters: {
    sceneId: 'home_mode',           // 自定义参数
    autoExecute: true
  }
};

// 获取 WantAgent
wantAgent.getWantAgent(want, (err, agent) => {
  if (err) {
    console.error(`获取 WantAgent 失败: ${err}`);
    return;
  }

  // 启动目标设备上的应用
  wantAgent.startAbility(agent, (err) => {
    if (!err) {
      promptAction.showToast({
        message: `场景已在 ${targetDeviceName} 上启动`
      });
    } else {
      console.error(`启动失败: ${err}`);
    }
  });
});
```

---

## 6. UI 组件库 API

### 6.1 基础组件速查

| 组件 | 适用场景 | 关键 API |
|------|---------|---------|
| `Button` | 主按钮、辅助按钮 | `type: ButtonType`, `stateEffect: boolean` |
| `Toggle` | 开关控件 | `type: ToggleType.Switch/Chip`, `isOn: boolean`, `onChange` |
| `Slider` | 滑块（需定制光感） | `value: number`, `min: number`, `max: number`, `step: number` |
| `TextField` | 文本输入 | `placeholder`, `controller`, `onChange` |
| `Search` | 搜索框 | `placeholder`, `onChange`, `onSubmit` |
| `Checkbox` | 多选框 | `isOn: boolean`, `onChange` |
| `Radio` | 单选框 | `isOn: boolean`, `groupName` |
| `Progress` | 进度条（圆形/线性） | `value: number`, `type: ProgressType` |

### 6.2 Toggle 组件

```typescript
Toggle({ type: ToggleType.Switch, isOn: this.devicePower })
  .selectedColor('#007DFF')           // 选中态颜色
  .switchPointColor('#FFFFFF')        // 滑块颜色
  .onChange((isOn: boolean) => {
    this.devicePower = isOn;
    this.syncPowerState(isOn);
  })
```

**ToggleType 枚举：**

| 类型 | 效果 |
|------|------|
| `ToggleType.Switch` | 开关控件 |
| `ToggleType.Chip` | 胶囊按钮控件 |

### 6.3 Slider 组件（原生滑块）

```typescript
Slider({
  value: this.brightness,
  min: 0,
  max: 100,
  step: 1,
  style: SliderStyle.OutSet           // OutSet=滑轨外侧，InSet=滑轨内侧
})
  .blockColor('#007DFF')             // 滑块颜色
  .trackColor('#E6E6E6')             // 滑轨背景色
  .selectedColor('#007DFF')           // 已选滑轨颜色
  .showTips(true)                     // 显示数值气泡
  .onChange((value: number) => {
    this.brightness = value;
    this.syncToDevice({ brightness: value });
  })
```

> **注意：** 原生 Slider 组件样式固定，若需实现沉浸光感滑动条，推荐基于 PanGesture + Stack 自定义实现（参考 Phase 2 代码示例）。

---

## 7. 安全与权限 API

### 7.1 权限配置（module.json5）

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.DISTRIBUTED_DEVICE_STATE_ACCESS",
        "reason": "$string:reason_device_access",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.DISTRIBUTED_DATASYNC",
        "reason": "$string:reason_data_sync",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:reason_internet",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      },
      {
        "name": "ohos.permission.LOCATION",
        "reason": "$string:reason_location",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

### 7.2 权限申请（运行时）

```typescript
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle';

// 检查权限状态
let atManager = abilityAccessCtrl.createAtManager();
atManager.checkAccessToken(
  bundleManager.getBundleInfo('com.smarthome.aihub', 0).bundleInfo.appInfo.accessTokenId,
  'ohos.permission.DISTRIBUTED_DEVICE_STATE_ACCESS',
  (err, result) => {
    if (result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // 已授权，直接使用
      this.initDeviceManager();
    } else {
      // 未授权，弹窗申请
      this.requestPermissions();
    }
  }
);

// 批量申请权限
atManager.requestPermissionsOnUser(
  ['ohos.permission.DISTRIBUTED_DEVICE_STATE_ACCESS',
   'ohos.permission.DISTRIBUTED_DATASYNC'],
  (err, results) => {
    if (err) {
      console.error(`权限申请失败: ${err}`);
      return;
    }
    if (results[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      this.initDeviceManager();
    }
  }
);
```

**权限申请场景说明（when 字段）：**

| 字段值 | 含义 | 适用场景 |
|--------|------|---------|
| `inuse` | 每次使用时授权 | 设备控制（用户主动操作时） |
| `always` | 始终授权（后台也可用） | 数据同步、位置触发自动化 |

---

## 8. API 异常处理汇总

### 8.1 异常处理总览

| 场景 | 异常表现 | 错误码 | 处理策略 |
|------|---------|--------|---------|
| 设备未发现 | 指令发送无响应 | `-1` | 启动 5 秒超时定时器，超时后 Toast "设备离线" |
| 网络不稳定 | 指令发送失败 | `-2` | 本地缓存指令，网络恢复后自动重发（最多 3 次） |
| 设备不支持指令 | 返回错误码 | `-3` | 解析错误码，显示"该设备不支持此操作" |
| 权限不足 | 弹窗被拒绝 | `-100` | 引导前往设置 > 权限管理 |
| KVStore 同步失败 | sync() 返回错误 | `err.code` | 降级到单设备存储，记录日志 |
| WantAgent 启动失败 | startAbility 报错 | `err.code` | 显示"目标设备响应超时" |
| 拖拽目标不在线 | onDrop 收到 -1 | `-1` | Toast "目标设备已离线，无法流转" |

### 8.2 超时处理模板

```typescript
private sendCommandWithTimeout(command: Command, timeoutMs: number = 5000): Promise<Result> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject({ code: -1, message: '指令发送超时' });
    }, timeoutMs);

    preferentiaManager.sendCommand(command)
      .then((result) => {
        clearTimeout(timer);
        resolve(result);
      })
      .catch((err) => {
        clearTimeout(timer);
        reject(err);
      });
  });
}

// 使用
this.sendCommandWithTimeout(cmd)
  .then((result) => {
    this.updateDeviceState(result);
  })
  .catch((err) => {
    this.handleCommandError(err);
  });
```

### 8.3 重试机制模板

```typescript
private async sendCommandWithRetry(command: Command, maxRetries: number = 3): Promise<Result> {
  let lastError;

  for (let i = 0; i < maxRetries; i++) {
    try {
      const result = await this.sendCommandWithTimeout(command);
      return result;
    } catch (err) {
      lastError = err;
      console.warn(`指令发送失败，第 ${i + 1} 次重试`);

      if (i < maxRetries - 1) {
        // 等待后重试（指数退避：1s, 2s, 4s）
        await this.sleep(Math.pow(2, i) * 1000);
      }
    }
  }

  throw lastError;
}

private sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

---

> **下一步：** 详见 Phase 5 文档《多设备形态适配指南》，包含手机 / 平板 / 智慧屏 / 智能手表的页面适配逻辑及布局代码示例。