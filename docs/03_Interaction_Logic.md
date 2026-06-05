# Phase 3：交互逻辑说明书

> **本文档版本：** v1.0  
> **编制日期：** 2026-06-04  
> **适配系统：** HarmonyOS 4.0+（NEXT / Dev Eco Studio 5.0+）  
> **所属项目：** SmartHome AIHub 鸿蒙全页面重构设计

---

## 📋 目录

1. [手势交互体系](#1-手势交互体系)
2. [页面转场动画](#2-页面转场动画)
3. [设备状态切换动效](#3-设备状态切换动效)
4. [跨设备拖拽交互](#4-跨设备拖拽交互)
5. [沉浸光感按键状态机](#5-沉浸光感按键状态机)
6. [异常交互处理](#6-异常交互处理)

---

## 1. 手势交互体系

### 1.1 手势总览

智能家居 APP 涉及以下核心手势，各手势在 ArkUI 中均有对应 API 支持：

| 手势 | API | 触发条件 | 适用场景 |
|------|-----|---------|---------|
| **点击 Tap** | `TapGesture` | 手指快触快放（< 300ms） | 按钮、开关、设备列表项 |
| **长按 LongPress** | `LongPressGesture` | 按住 ≥ 500ms 不移动 | 场景卡片编辑、设备详情入口 |
| **双击 DoubleTap** | `DoubleTapGesture` | 300ms 内连续两次点击 | 设备大图放大、全屏查看 |
| **滑动 Pan** | `PanGesture` | 按下后移动 ≥ 10vp | 滑块调节、页面左右滑动 |
| **捏合 Pinch** | `PinchGesture` | 两指缩放 | 图表缩放、手表端卡片放大 |
| **拖拽 Drag** | `DragEvent` | 长按后拖动 ≥ 20vp | 场景编辑编排区、跨设备流转 |
| **旋转 Rotation** | `RotationGesture` | 双指旋转 | 智慧屏旋转角度控制（可选） |
| **摇一摇** | `摇晃监听` | 设备摇一摇 | 配网场景（扫码相关） |

### 1.2 点击手势（TapGesture）

**基础点击：**

```typescript
TapGesture()
  .onAction((event: GestureEvent) => {
    // 点击瞬间触发
    this.onTap();
  })
```

**参数配置：**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `fingers` | number | 1 | 需要的手指数量（1-10） |
| `distance` | number | 10vp | 被判定为点击的最大移动距离 |

**多击识别：**

```typescript
// 双击手势通常与单击配合使用，通过手势竞争实现
GestureGroup(GestureMode.Exclusive,
  DoubleTapGesture()
    .onAction(() => { this.handleDoubleTap(); }),
  TapGesture()
    .onAction(() => { this.handleTap(); })
)
```

### 1.3 滑动手势（PanGesture）

**滑块调节完整实现：**

```typescript
PanGesture()
  .onActionStart((event: GestureEvent) => {
    // 手指按下滑轨的瞬间
    this.isSliding = true;
    this.thumbScale = 1.15; // 滑块放大
    this.sliderX = event.localX; // 记录起始位置
  })
  .onActionUpdate((event: GestureEvent) => {
    // 拖动过程中（每帧更新）
    const deltaX = event.localX - this.startX;
    const newValue = this.clamp(
      this.currentValue + (deltaX / this.trackWidth) * (this.max - this.min),
      this.min,
      this.max
    );
    this.value = Math.floor(newValue);
  })
  .onActionEnd((event: GestureEvent) => {
    // 手指抬起
    this.isSliding = false;
    this.thumbScale = 1;
    // 同步设备状态
    this.syncToDevice(this.value);
  })
```

**PanGesture 参数：**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `direction` | PanDirection | PanDirection.All | 允许的滑动方向 |
| `distance` | number | 10vp | 被判定为滑动的最小距离 |
| `fingers` | number | 1 | 需要的手指数量 |

### 1.4 长按手势（LongPressGesture）

**场景编辑长按进入拖拽：**

```typescript
LongPressGesture()
  .onAction((event: GestureEvent) => {
    // 长按 500ms 后触发，进入编辑模式
    if (event.repeat === false) { // 只触发一次
      this.enterEditMode();
    }
  })
```

**与 Drag 配合（长按后拖拽）：**

```typescript
.gesture(
  DragGesture()
    .onActionStart((event: DragEvent) => {
      // 拖拽开始
      this.isDragging = true;
      this.dragOpacity = 0.8;
    })
    .onActionUpdate((event: DragEvent) => {
      // 拖拽过程中更新位置
      this.dragX = event.globalX;
      this.dragY = event.globalY;
    })
    .onActionEnd((event: DragEvent) => {
      // 拖拽结束，触发放置逻辑
      this.handleDrop(event);
      this.isDragging = false;
      this.dragOpacity = 1;
    })
)
```

### 1.5 拖拽手势（DragEvent）— 跨设备流转核心

DragEvent 是实现跨设备流转的核心 API，允许将一个组件的拖拽数据传输到另一个设备：

**拖拽发起端（手机 → 智慧屏）：**

```typescript
// 设备卡片设置为拖拽源
DeviceCard({ device: this.device })
  .draggable(true) // 启用拖拽
  .onDragStart((event: DragEvent) => {
    // 拖拽开始时设置数据
    event.setData({
      'deviceId': this.device.id,
      'deviceName': this.device.name,
      'deviceType': this.device.type,
      'action': JSON.stringify({
        command: 'turnOn',
        params: { brightness: 80 }
      })
    });

    // 设置跨设备流转标识
    event.setDragDpid('SAME_NETWORK'); // 同网络内所有可信设备

    // 拖拽预览效果
    event.setPreviewRect({
      x: event.localX - 50,
      y: event.localY - 50,
      w: 100,
      h: 100
    });
  })
  .onDragMove((event: DragEvent) => {
    // 拖拽过程中（可选，用于预览跟随）
  })
  .onDragEnd((event: DragEvent) => {
    // 拖拽结束（本端）
    if (event.getResult() === 0) {
      // 拖拽成功被目标接收
    }
  })
```

**拖拽接收端（智慧屏）：**

```typescript
// 执行动作编辑区设置为放置目标
DropTarget()
  .onDrop((event: DragEvent) => {
    // 获取拖拽数据
    const data = event.getData();
    const action = JSON.parse(data['action']);

    // 解析设备信息
    const deviceId = data['deviceId'];
    const deviceName = data['deviceName'];

    // 添加到执行动作列表
    this.actionList.push({
      deviceId: deviceId,
      deviceName: deviceName,
      action: action
    });

    // 播放接收成功动画
    this.playDropSuccessAnim();
  })
  .onDragEnter((event: DragEvent) => {
    // 拖拽进入目标区域，高亮目标
    this.isDropTargetActive = true;
  })
  .onDragLeave((event: DragEvent) => {
    // 拖拽离开目标区域，取消高亮
    this.isDropTargetActive = false;
  })
```

---

## 2. 页面转场动画

### 2.1 标准页面转场

| 转场类型 | 使用场景 | 动画效果 | 时长 |
|---------|---------|---------|------|
| `push` | 进入下级页面 | 从右向左滑入 | 300ms |
| `pop` | 返回上级页面 | 从左向右滑出 | 300ms |
| `replace` | 替换当前页面 | 渐隐替换 | 200ms |
| `back` | 返回指定页 | 叠加层弹出 | 250ms |

**ArkUI 实现：**

```typescript
// push 推入新页面
router.pushUrl({
  url: 'pages/DeviceDetail',
  params: { deviceId: 'light_001' }
}, {
  animation: {
    type: router.RouterAnimation.Push,
    duration: 300,
    curve: Curve.FastOutSlowIn
  }
});

// pop 返回上一页
router.pop();

// replace 替换当前页
router.replaceUrl({
  url: 'pages/DeviceList',
  params: { category: 'all' }
}, {
  animation: {
    type: router.RouterAnimation.Replace,
    duration: 200,
    curve: Curve.EaseOut
  }
});
```

### 2.2 自定义转场动画

```typescript
// 使用 animateTo 实现自定义转场
animateTo({
  duration: 350,
  curve: Curve.FastOutSlowIn,
  animations: () => {
    // 当前页面退出动画
    this.currentPageOpacity = 0;
    this.currentPageTranslateX = -50;
    // 目标页面进入动画
    this.nextPageOpacity = 1;
    this.nextPageTranslateX = 0;
  }
}, () => {
  // 动画完成后切换页面
  this.currentPage = this.nextPage;
  this.currentPageOpacity = 1;
  this.currentPageTranslateX = 0;
})
```

### 2.3 页面共享元素转场（Shared Element Transition）

| 场景 | 实现效果 |
|------|---------|
| 设备列表卡片 → 详情页 | 设备图标从列表位置放大到详情页顶部位置（类似 Flutter Hero） |

> **注意：** ArkUI 当前版本对共享元素转场的支持有限，建议通过自定义动画模拟：

```typescript
// 从列表页点击卡片时，传递起始位置信息
router.pushUrl({
  url: 'pages/DeviceDetail',
  params: {
    deviceId: this.device.id,
    sharedElement: {
      iconX: this.iconAreaX,
      iconY: this.iconAreaY,
      iconWidth: 48,
      iconHeight: 48
    }
  }
});

// 详情页根据传入位置播放展开动画
aboutToAppear() {
  const params = router.getParams();
  if (params.sharedElement) {
    animateTo({
      duration: 400,
      curve: Curve.FastOutSlowIn,
      animations: () => {
        this.iconScale = 1;
        this.iconTranslateX = 0;
        this.iconTranslateY = 0;
      }
    });
  }
}
```

---

## 3. 设备状态切换动效

### 3.1 开关 Toggle 光感扫动效果

开关是最核心的设备控制控件，其光感扫动效果实现逻辑：

```
┌────────────────────────────────────────────────────────────────┐
│                   Toggle 切换光感时序                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  状态: OFF ──────────────────────────────► ON                 │
│                                                                │
│  时间轴:  t=0              t=100ms        t=250ms            │
│          │                  │                │                   │
│          ▼                  ▼                ▼                   │
│        ┌────┐            ┌────┐          ┌────┐                │
│        │ ○  │  ──────►  │ ◐  │  ───►   │ ●  │                │
│        │  ← │            │ ◀── │          │    │                │
│        └────┘            └────┘          └────┘                │
│          │                │                │                   │
│          │ 光感爆发      │ 光感扩散       │ 光感消退           │
│          │ (100ms)      │ (150ms)        │ (消退动画)         │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**ArkUI 实现代码：**

```typescript
@Component
struct HaloToggle {
  @Link isOn: boolean;
  @State thumbX: number = 2;
  @State trackBgColor: string = '#E6E6E6';
  @State glowIntensity: number = 0;
  @State thumbScale: number = 1;

  aboutToAppear() {
    // 初始化状态
    this.thumbX = this.isOn ? 26 : 2;
    this.trackBgColor = this.isOn ? '#007DFF' : '#E6E6E6';
  }

  build() {
    Stack() {
      // 底层 Track（滑轨）
      Rect()
        .width(52)
        .height(28)
        .fill(this.trackBgColor)
        .radius(14)
        .animation({ duration: 250, curve: Curve.EaseOut })

      // 光感叠加层（扫动效果核心）
      Rect()
        .width(52)
        .height(28)
        .fill(
          new LinearGradient({
            direction: GradientDirection.Left,
            colors: [['#FFFFFFFF', 0], ['#00A5FF', 0.3], ['#FFFFFFFF', 0.6]]
          })
        )
        .radius(14)
        .opacity(this.glowIntensity * 0.25)
        .animation({ duration: 150 })

      // Thumb（滑块）
      Circle()
        .width(24 * this.thumbScale)
        .height(24 * this.thumbScale)
        .fill('#FFFFFF')
        .shadow({
          radius: this.isOn ? 10 : 6,
          color: this.isOn ? '#33007DFF' : '#22000000',
          offsetX: 0,
          offsetY: 2
        })
        .translate({ x: this.thumbX, y: 2 })
        .animation({ duration: 250, curve: Curve.EaseOut })
    }
    .width(52)
    .height(28)
    .gesture(
      TapGesture()
        .onAction(() => {
          // 切换前：光感爆发
          animateTo({ duration: 80 }, () => {
            this.glowIntensity = 1.0;
            this.thumbScale = 1.1;
          });

          // 执行切换
          this.isOn = !this.isOn;

          // 切换后：光感消退 + 状态更新
          animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
            this.glowIntensity = 0;
            this.thumbScale = 1;
            this.thumbX = this.isOn ? 26 : 2;
            this.trackBgColor = this.isOn ? '#007DFF' : '#E6E6E6';
          });

          // 同步设备状态
          this.syncToDevice();
        })
    )
  }

  private syncToDevice(): void {
    // preferentiaManager.sendCommand(...)
  }
}
```

### 3.2 设备卡片状态呼吸动画

设备在线时，卡片左侧产生微弱呼吸光效，表示设备处于"活跃等待"状态：

```typescript
// 呼吸光动画（持续循环）
定时器（0~3000ms 循环）{
  // 透明度从 0.3 → 0.7 → 0.3
  animateTo({
    duration: 1500,
    curve: Curve.EaseInOut,
    iterations: 1,
    playMode: PlayMode.Alternate
  }, () => {
    this.breathOpacity = 0.7;
  });
}
```

---

## 4. 跨设备拖拽交互

### 4.1 跨设备流转完整流程

```
┌──────────────────────────────────────────────────────────────────┐
│               跨设备拖拽流转时序图                               │
├──────────────────────────────────────────────────────────────────┤
│                                                              │
│  【手机端】                【网络传输】           【智慧屏端】   │
│                                                              │
│   长按设备卡片              │                  目标区域       │
│        │                   │                  高亮           │
│        ▼                   │                     │            │
│   拖拽开始                 │                     ▼            │
│   setDragData              │── 跨设备 DragEvent ──►           │
│        │                   │                     │            │
│        ▼                   │                     ▼            │
│   拖拽预览                 │                 onDrop          │
│   跟随手指                 │                  接收数据      │
│        │                   │                     │            │
│        ▼                   │                     ▼            │
│   拖拽释放                 │                  执行动作       │
│   onDragEnd                │── 结果回传 ◄───── 动作完成     │
│        │                   │                     │            │
│        ▼                   │                     ▼            │
│   收到结果反馈             │                 Toast 提示      │
│   Toast 显示               │                                │
│                                                              │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 超级终端流转（Super Device Flow）

鸿蒙分布式能力的核心场景：**手机上的场景"回家模式"，一键流转到智慧屏自动执行**。

```typescript
// 场景激活时，检测同局域网内的可信设备
import deviceManager from '@ohos.distributedhardware.deviceManager';

// 获取可信设备列表
deviceManager.getTrustedDeviceList((err, list) => {
  if (err) return;

  list.forEach((device) => {
    // 过滤支持场景执行的设备类型
    if (device.type === 'smart_screen' || device.type === 'tablet') {
      // 向目标设备发送场景执行请求
      this.sendSceneToDevice(scene, device.deviceId);
    }
  });
});

// 跨设备发送场景
private sendSceneToDevice(scene: Scene, targetDeviceId: string): void {
  // 使用 want-agent 实现跨设备启动
  import wantAgent from '@ohos.wantAgent';

  let want = {
    deviceId: targetDeviceId,
    bundleName: 'com.smarthome.aihub',
    abilityName: 'EntryAbility',
    parameters: {
      sceneId: scene.id,
      autoExecute: true
    }
  };

  wantAgent.getWantAgent(want, (err, agent) => {
    if (!err) {
      wantAgent.startAbility(agent, (err) => {
        if (!err) {
          promptAction.showToast({
            message: `场景已在 ${deviceName} 上启动`
          });
        }
      });
    }
  });
}
```

---

## 5. 沉浸光感按键状态机

### 5.1 状态机定义

```
┌─────────────────────────────────────────────────────────────────┐
│                 沉浸光感按键状态机                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                         ┌─────────────┐                        │
│                         │  Disabled   │                        │
│                         └──────┬──────┘                        │
│                                │                               │
│              ┌─────────────────┼─────────────────┐             │
│              │                 │                 │             │
│              ▼                 ▼                 ▼             │
│        ┌─────────┐       ┌─────────┐      ┌─────────┐       │
│        │ Default │◄────►│  Hover  │      │ Active  │       │
│        └────┬────┘       └────┬────┘      └────┬────┘       │
│             │                │                │              │
│             │◄──────────────┘                │              │
│             │                │                 │              │
│             ▼                │                 ▼              │
│        ┌─────────┐          │          ┌─────────┐       │
│        │ Pressed │──────────►│          │  Default│       │
│        └────┬────┘          │          └────┬────┘       │
│             │               │               │              │
│             │ (on:true)    │               │              │
│             ▼               │               │              │
│        ┌─────────┐         │               │              │
│        │ Active  │─────────┴───────────────┘              │
│        └─────────┘                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 状态转换时序详表

| 当前状态 | 事件 | 下一状态 | 时长 | 动画曲线 |
|---------|------|---------|------|---------|
| Default | onHoverStart | Hover | 200ms | EaseOut |
| Default | onTap | Pressed | 100ms | FastOutSlowIn |
| Default | isOn:true | Active | 200ms | EaseOut |
| Hover | onHoverEnd | Default | 150ms | EaseIn |
| Hover | onTap | Pressed | 100ms | — |
| Pressed | onTapEnd + on:true | Active | 200ms | EaseOut |
| Pressed | onTapEnd | Default | 150ms | EaseOut |
| Active | onTap (toggle off) | Default | 200ms | EaseOut |
| Active | onTap (toggle on, already on) | Active | — | — |

### 5.3 状态视觉参数详表

| 状态 | glowBlur | glowOpacity | glowColor | scale | borderColor |
|------|----------|-------------|-----------|-------|-------------|
| Default | 0 | 0 | transparent | 1.0 | transparent |
| Hover | 10vp | 20% | #007DFF | 1.02 | #33007DFF |
| Pressed | 6vp | 30% | #007DFF | 0.97 | #66007DFF |
| Active | 20vp | 40% | #007DFF | 1.0 | #007DFF |
| Disabled | 0 | 0 | transparent | 1.0 | transparent |

### 5.4 ArkUI 状态机实现

```typescript
@Component
struct HaloButton {
  @Link isActive: boolean;
  @State currentState: ButtonState = ButtonState.Default;
  @State glowOpacity: number = 0;
  @State scale: number = 1;
  @State glowRadius: number = 0;

  enum ButtonState {
    Default,
    Hover,
    Pressed,
    Active,
    Disabled
  }

  build() {
    Button()
      .width('100%')
      .height(48)
      .borderRadius(12)
      .backgroundColor(this.isActive ? '#007DFF' : '#F2F5F7')
      .border({
        width: this.currentState === ButtonState.Hover ||
               this.currentState === ButtonState.Active ? 1 : 0,
        color: this.currentState === ButtonState.Active ? '#007DFF' : '#66007DFF'
      })
      .shadow({
        radius: this.glowRadius,
        color: `rgba(0, 125, 255, ${this.glowOpacity})`,
        offsetX: 0,
        offsetY: 0
      })
      .scale({ x: this.scale, y: this.scale })
      .animation({
        duration: this.currentState === ButtonState.Pressed ? 100 : 200,
        curve: Curve.EaseOut
      })
      .onTouch((event: TouchEvent) => {
        switch (event.type) {
          case TouchType.Down:
            this.currentState = ButtonState.Pressed;
            this.scale = 0.97;
            this.glowOpacity = 0.3;
            this.glowRadius = 6;
            break;
          case TouchType.Up:
          case TouchType.Cancel:
            if (this.isActive) {
              this.currentState = ButtonState.Active;
            } else {
              this.currentState = ButtonState.Default;
            }
            this.scale = 1;
            this.glowOpacity = this.isActive ? 0.4 : 0;
            this.glowRadius = this.isActive ? 20 : 0;
            break;
        }
      })
      .gesture(
        TapGesture()
          .onAction(() => {
            this.isActive = !this.isActive;
            // Active 激活动画
            if (this.isActive) {
              animateTo({ duration: 100 }, () => {
                this.glowOpacity = 1;
                this.glowRadius = 25;
              });
              animateTo({ duration: 200, delay: 100 }, () => {
                this.glowOpacity = 0.4;
                this.glowRadius = 20;
              });
            }
          })
      )
  }
}
```

---

## 6. 异常交互处理

### 6.1 超时反馈处理

| 操作 | 超时阈值 | 反馈方式 |
|------|---------|---------|
| 设备开关切换 | 3 秒 | 无响应后显示 loading 状态，5 秒后 Toast "设备无响应" |
| 设备状态刷新 | 5 秒 | 显示"离线"状态，自动重试一次 |
| 场景激活 | 10 秒 | Toast "场景执行超时，请检查设备连接" |
| 跨设备流转 | 15 秒 | Toast "设备未响应，流转失败" |
| 设备添加配网 | 60 秒 | 引导页提示"配网失败，请检查设备是否进入配网模式" |

### 6.2 离线降级处理

当检测到设备离线时：

```
┌─────────────────────────────────────────────────────────────┐
│                    离线状态降级流程                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  检测到设备离线                                               │
│       │                                                      │
│       ▼                                                      │
│  ┌─────────────┐                                             │
│  │ 离线状态 UI │  → 设备卡片变灰 + 状态文字"离线"             │
│  └──────┬──────┘                                             │
│         │                                                    │
│         ▼                                                    │
│  开关操作？                                                 │
│    │                                                        │
│    ├─ Yes ──► 提示"设备已离线，操作将在恢复后执行"          │
│    │           （缓存操作到队列）                            │
│    │                                                        │
│    └─ No ──► 仅显示状态，不做操作                           │
│                                                              │
│         │                                                    │
│         ▼                                                    │
│  设备恢复在线                                               │
│         │                                                    │
│         ▼                                                    │
│  重发缓存队列中的操作 → 反馈执行结果                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 6.3 操作可逆性保障

| 操作类型 | 可逆性 | 回退方案 |
|---------|--------|---------|
| 开关切换 | 可逆 | 再次切换即回退，超时自动回退（5秒） |
| 亮度调节 | 可逆 | 拖回原位置即回退，或"重置"按钮恢复默认值 |
| 场景激活 | 部分可逆 | 提供"撤销场景"按钮，执行反向动作 |
| 设备删除 | 不可逆 | 二次确认弹窗，明确告知后果 |
| 定时删除 | 可逆 | 提供 5 秒取消窗口 |

### 6.4 异常状态 UI 模板

```typescript
@Builder buildOfflineOverlay() {
  Stack() {
    // 设备灰度处理
    Image(this.device.icon)
      .saturation(0) // 灰度化
      .opacity(0.6)

    // 离线标签
    Row() {
      Image($r('app.media.icon_offline'))
        .width(16)
        .height(16)
      Text('离线')
        .fontSize(12)
        .fontColor('#FF3B30')
    }
    .backgroundColor('rgba(0,0,0,0.6)')
    .borderRadius(12)
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
  }
  .onClick(() => {
    promptAction.showToast({ message: '设备已离线，请检查网络连接' });
  })
}
```

---

> **下一步：** 详见 Phase 4 文档《技术接入手册》，包含所有 API 接口清单、调用的前置条件、核心参数及异常处理方案。