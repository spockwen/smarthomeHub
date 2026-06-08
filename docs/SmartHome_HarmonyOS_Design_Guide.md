# 智能家居 APP 鸿蒙（HarmonyOS）全页面重构设计方案

> **文档版本：** v1.0  
> **编制日期：** 2026-06-04  
> **适配系统：** HarmonyOS 4.0+（NEXT/Dev Eco Studio 5.0+）  
> **技术栈：** ArkTS / ArkUI / Stage 模型 / HAP

---

## 📋 目录

1. [设计背景与核心目标](#1-设计背景与核心目标)
2. [全页面设计稿](#2-全页面设计稿)
3. [沉浸光感交互设计详解](#3-沉浸光感交互设计详解)
4. [技术接入手册（API 清单）](#4-技术接入手册api-清单)
5. [跨设备形态适配逻辑](#5-跨设备形态适配逻辑)
6. [差异化设计要点](#6-差异化设计要点)

---

## 1. 设计背景与核心目标

### 1.1 项目背景

智能家居 APP 承载着用户对设备控制、场景联动、能耗管理的核心诉求。随着鸿蒙生态的快速扩张，分布式能力、原子化服务、跨设备流转已成为鸿蒙独有的体验壁垒。本设计文档旨在将现有智能家居 APP 依照 HarmonyOS Design 规范进行全面重构，聚焦以下核心价值：

| 维度 | 目标 |
|------|------|
| **沉浸光感** | 控件具备真实的光影反馈，如同触碰真实物理按键 |
| **轻量化** | 利用 ArkUI 声明式 UI 减少渲染开销，页面秒开 |
| **跨设备协同** | 手机 / 平板 / 智慧屏 / 手表统一体验，设备间无缝流转 |
| **即时反馈** | 设备状态毫秒级同步，操作结果零延迟感知 |

### 1.2 核心场景覆盖

```
├── 首页（设备概览 + 快捷控制）
├── 设备详情页（单设备精细控制）
├── 场景编辑页（自动化编排）
├── 设备管理页（设备列表 / 分组 / 管理）
├── 个人中心（账户 / 设置 / 数据统计）
└── 能耗统计页（数据可视化）
```

### 1.3 鸿蒙设计语言核心原则

依据 HarmonyOS Design 官方规范，本设计遵循以下六大原则：

1. **简约** — 去除冗余装饰，内容即界面
2. **自然** — 符合直觉的操作逻辑，降低学习成本
3. **通透** — 背景层与内容层光感一致，视觉层次清晰
4. **一致性** — 全端体验统一，跨设备行为一致
5. **响应式** — 自适应不同设备形态与屏幕尺寸
6. **容错性** — 操作可逆，状态可预期

---

## 2. 全页面设计稿

### 2.1 设计规范速查表

#### 2.1.1 色彩系统（HarmonyOS Palette）

| 语义色 | Hex 值 | 用途说明 |
|--------|--------|----------|
| 品牌主色 | `#007DFF` | 按钮、开关 ON 状态、选中态 |
| 品牌辅色 | `#00A5FF` | 渐变、hover、光感叠加层 |
| 功能成功 | `#00C854` | 设备在线、正向操作反馈 |
| 功能警告 | `#FFB800` | 离线警告、低电量提示 |
| 功能错误 | `#FF3B30` | 异常状态、故障提示 |
| 背景色 light | `#F2F5F7` | 页面背景（浅色模式） |
| 背景色 dark | `#0D0D0D` | 页面背景（深色模式） |
| 表面色 light | `#FFFFFF` | 卡片、控件底板 |
| 表面色 dark | `#1A1A1A` | 卡片、控件底板（深色模式） |
| 文字 primary light | `#E6FFFFFF` | 深色模式主文字 |
| 文字 primary dark | `#E6000000` | 浅色模式主文字 |
| 文字 secondary | `#99000000` | 次要说明文字 |

#### 2.1.2 字体规范

| 字体层级 | 字号 | 字重 | 场景 |
|----------|------|------|------|
| Display | 36vp | Bold | 页面大标题 |
| Title 1 | 28vp | Medium | 模块标题 |
| Title 2 | 22vp | Medium | 卡片标题 |
| Body | 16vp | Regular | 正文内容 |
| Caption | 12vp | Regular | 辅助说明 |
| Numeric | 32vp | Bold | 数据展示（设备数值、时间） |

> **注：** 鸿蒙使用 `font-family: "HarmonyOS Sans"` 作为默认字体，数字推荐使用 `font-family: "HarmonyOS Sans-Numeric"` 以获得更好的等宽显示效果。

#### 2.1.3 间距系统（4pt 基准网格）

| 间距等级 | 尺寸 | 适用场景 |
|----------|------|----------|
| xs | 4vp | 组件内部紧凑间距 |
| sm | 8vp | 列表项内间距 |
| md | 12vp | 区块内间距 |
| lg | 16vp | 区块间标准间距 |
| xl | 24vp | 页面左右安全边距 |
| xxl | 32vp | 大区块分隔 |

#### 2.1.4 圆角规范

| 组件 | 圆角半径 |
|------|----------|
| 小控件（图标按钮） | 8vp |
| 卡片/容器 | 16vp |
| 大模态弹窗 | 24vp |
| 全屏页面 | 0（无边） |

---

### 2.2 首页（Home）

#### 2.2.1 页面结构

```
┌─────────────────────────────────────────────┐
│ 状态栏（系统级）                             │
├─────────────────────────────────────────────┤
│ ┌─────────────────┐  ┌─────────────────┐  │
│ │   用户问候区     │  │   消息通知入口   │  │
│ │  "早上好，XX"   │  │      🔔         │  │
│ └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐│
│ │         今日天气 + 室内环境卡片           ││
│ │   🌡 室温 26°C | 💧 湿度 58% | 🔋 电力   ││
│ └─────────────────────────────────────────┘│
├─────────────────────────────────────────────┤
│         快捷场景入口（横向滚动）              │
│  ┌────────┐ ┌────────┐ ┌────────┐         │
│  │ 回家   │ │ 离家   │ │ 睡眠   │   +更多  │
│  └────────┘ └────────┘ └────────┘         │
├─────────────────────────────────────────────┤
│              设备总览列表                    │
│  ┌─────────────────────────────────────────┐│
│  │ 🏠 客厅灯        [ON]  ⚡ 已开启         ││
│  ├─────────────────────────────────────────┤│
│  │ ❄️ 空调          [OFF] ⚡ 已关闭         ││
│  ├─────────────────────────────────────────┤│
│  │ 📺 电视          [ON]  ⚡ 已开启         ││
│  ├─────────────────────────────────────────┤│
│  │ 🚪智能门锁      [LOCK] 🔒 已锁定        ││
│  └─────────────────────────────────────────┘│
├─────────────────────────────────────────────┤
│           + 新增设备（悬浮按钮）             │
├─────────────────────────────────────────────┤
│  首页 │ 场景 │ 设备 │ 我的                     │
│        （底部 Tab 导航）                      │
└─────────────────────────────────────────────┘
```

#### 2.2.2 关键控件设计

**快捷场景卡片（SceneCard）**

- 尺寸：120vp × 120vp（含图标 48vp）
- 光感实现：场景激活时，边框产生 `brand` 色光晕渐变（`#007DFF → #00A5FF`），使用 `blur(20vp)` 外发光叠加
- 状态色：激活态卡片背景 `rgba(0, 125, 255, 0.1)`；待机态背景 `#F2F5F7`
- 触控热区：最小 44vp × 44vp（满足无障碍触控面积）

**设备列表项（DeviceListItem）**

- 布局：左图标的 48vp + 设备名称 + 状态文字 + 右侧控制开关
- 开关控件：采用 HarmonyOS native `Toggle` 组件，类型 `ToggleType.Switch`
- 光感反馈：开关切换时，Track 轨道产生光感从左向右的扫动效果（`@State` 驱动 opacity + translateX 动画）

#### 2.2.3 首页布局 ArkUI 代码示例

```typescript
// ArkUI 声明式 UI 示例（简化版）
@Entry
@Component
struct HomePage {
  @State deviceList: Device[] = [];
  @State sceneList: Scene[] = [];
  @State greeting: string = '';
  @State indoorInfo: IndoorInfo = new IndoorInfo();

  aboutToAppear() {
    this.greeting = this.getGreeting();
    this.loadData();
  }

  build() {
    Scroll() {
      Column() {
        // 问候区
        this.buildHeader()
        // 室内环境卡片
        this.buildEnvironmentCard()
        // 快捷场景
        this.buildSceneRow()
        // 设备列表
        this.buildDeviceList()
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollBar(BarState.Off)
    .backgroundColor('#F2F5F7')
  }

  @Builder buildHeader() {
    Row() {
      Column() {
        Text(this.greeting)
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor('#E6000000')
        Text('您有 3 台设备在线')
          .fontSize(12)
          .fontColor('#66000000')
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Image($r('app.media.icon_notification'))
        .width(24)
        .height(24)
    }
    .width('100%')
    .height(64)
    .padding({ top: 8 })
  }

  @Builder buildEnvironmentCard() {
    Row() {
      this.buildEnvItem('app.media.icon_temp', '室温', this.indoorInfo.temp + '°C')
      Divider().width('1vp').height(40)
      this.buildEnvItem('app.media.icon_humidity', '湿度', this.indoorInfo.humidity + '%')
      Divider().width('1vp').height(40)
      this.buildEnvItem('app.media.icon_power', '电力', this.indoorInfo.power + 'kWh')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ top: 16, bottom: 16 })
    .margin({ top: 8 })
  }

  @Builder buildEnvItem(icon: Resource, label: string, value: string) {
    Column() {
      Image(icon).width(24).height(24)
      Text(label).fontSize(12).fontColor('#99000000').margin({ top: 4 })
      Text(value).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#E6000000')
    }
    .layoutWeight(1)
  }

  @Builder buildSceneRow() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.sceneList, (scene: Scene) => {
          SceneCard({ scene: scene })
            .onClick(() => this.activateScene(scene))
        })
        // 添加更多场景
        AddSceneButton()
      }
      .padding({ top: 16, bottom: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder buildDeviceList() {
    Column() {
      Row() {
        Text('设备总览')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('查看全部 >')
          .fontSize(12)
          .fontColor('#99000000')
      }
      .width('100%')
      .padding({ bottom: 8 })

      ForEach(this.deviceList, (device: Device) => {
        DeviceListItem({ device: device })
          .onClick(() => this.navigateToDevice(device))
      })
    }
    .margin({ top: 8 })
  }

  private activateScene(scene: Scene): void {
    // 场景激活逻辑
  }

  private navigateToDevice(device: Device): void {
    // 跳转设备详情
  }

  private getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 6) return '凌晨好';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }
}
```

---

### 2.3 设备详情页（Device Detail）

#### 2.3.1 页面结构

```
┌─────────────────────────────────────────────┐
│  ← 返回         客厅灯              ⋮ 更多   │
├─────────────────────────────────────────────┤
│                                             │
│         ┌───────────────────┐              │
│         │                   │              │
│         │     设备图标       │              │
│         │    （大尺寸）      │              │
│         │                   │              │
│         │   💡 氛围光效果    │              │
│         │   （动态光晕）     │              │
│         └───────────────────┘              │
│                                             │
│            客厅主灯                          │
│          当前状态：已开启                    │
│          当前亮度：80%                       │
│                                             │
├─────────────────────────────────────────────┤
│              控制面板                        │
│  ┌─────────────────────────────────────────┐│
│  │  亮度调节                    80%        ││
│  │  ═══════════════●════════  0% ── 100% ││
│  └─────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────┐│
│  │  色温调节                    暖光       ││
│  │  ═══════════●═════════════  2700K─6500K││
│  └─────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────┐│
│  │  情景模式                                ││
│  │  [阅读] [影院] [浪漫] [节能]            ││
│  └─────────────────────────────────────────┘│
├─────────────────────────────────────────────┤
│           设备信息卡片                       │
│  ┌─────────────────────────────────────────┐│
│  │  型号：LS-M1 Pro    版本：v2.3.1        ││
│  │  MAC：12:34:56:78:9A:BC                 ││
│  │  固件：最新版本 ✓                       ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

#### 2.3.2 沉浸光感滑动条（LightSlider）实现

滑动条是设备详情页的核心光感控件，其光感效果体现在：

1. **滑块光晕**：滑块 Thumb 持续发出柔和光晕，随拖动位置动态跟随
2. **轨迹光感**：滑轨 Track 产生从左侧已填充色到右侧未填充色的渐变过渡
3. **状态光影层级**：

| 层级 | 视觉表现 | 实现方式 |
|------|----------|----------|
| 底层 | 滑轨背景灰 | Static 静态渲染 |
| 中层 | 已填充进度光感 | Gradient + opacity 动画 |
| 顶层 | 滑块光晕 | blur(30vp) + shadow |

#### 2.3.3 ArkUI 光感滑动条核心实现

```typescript
@Component
struct LightSlider {
  @Link value: number; // 0-100
  @State sliderX: number = 0;
  @State isDragging: boolean = false;
  private min: number = 0;
  private max: number = 100;

  private get thumbOffset(): Length {
    const percent = (this.value - this.min) / (this.max - this.min);
    return px2vp(this.sliderX * percent);
  }

  build() {
    Stack() {
      // 底层滑轨
      Row() {
        Rect()
          .width('100%')
          .height(6)
          .fill('#E6E6E6')
          .radius(3)
      }
      .width('100%')

      // 已填充进度（光感渐变）
      Row() {
        Rect()
          .fill(
            new LinearGradient({
              direction: GradientDirection.Left,
              colors: [['#007DFF', 0], ['#00A5FF', 1]]
            })
          )
          .width(this.thumbOffset)
          .height(6)
          .radius(3)
      }
      .width('100%')
      .clip(true)
      .opacity(this.isDragging ? 0.9 : 1.0) // 拖动时略微提亮

      // 滑块（光晕效果）
      Circle()
        .width(this.isDragging ? 28 : 24)
        .height(this.isDragging ? 28 : 24)
        .fill('#007DFF')
        .shadow({
          radius: this.isDragging ? 20 : 10,
          color: '#33007DFF', // 30% 透明度蓝色光晕
          offsetX: 0,
          offsetY: 4
        })
        .translate({ x: this.thumbOffset - (this.isDragging ? 14 : 12) })
        .animation({
          duration: 150,
          curve: Curve.EaseOut
        })
    }
    .width('100%')
    .height(40)
    .gesture(
      PanGesture()
        .onStart(() => {
          this.isDragging = true;
        })
        .onUpdate((event) => {
          this.sliderX = event.localX;
          this.value = Math.floor(
            this.min + (event.localX / this.sliderX) * (this.max - this.min)
          );
        })
        .onEnd(() => {
          this.isDragging = false;
          // 同步设备状态
          this.syncToDevice();
        })
    )
  }

  private syncToDevice(): void {
    // 调用设备通信 API
  }
}
```

---

### 2.4 场景编辑页（Scene Editor）

#### 2.4.1 页面结构

```
┌─────────────────────────────────────────────┐
│  ← 取消        新建场景          保存 →       │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │  场景图标（可自定义上传）               ││
│  │         🏠                               ││
│  └─────────────────────────────────────────┘│
│                                             │
│  场景名称                                    │
│  ┌─────────────────────────────────────────┐│
│  │  输入场景名称...                        ││
│  └─────────────────────────────────────────┘│
│                                             │
│  触发条件（可多选）                          │
│  ┌─────────────────────────────────────────┐│
│  │  ○ 时间触发    ○ 位置触发   ○ 设备触发  ││
│  └─────────────────────────────────────────┘│
│                                             │
│  条件配置区                                  │
│  ┌─────────────────────────────────────────┐│
│  │  当 [设备] [状态] 时                    ││
│  │  执行 [设备1] → [开]                    ││
│  │  执行 [设备2] → [亮度调至 50%]          ││
│  │                         [+ 添加执行动作]  ││
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │  执行时间段（可选）                      ││
│  │  [06:00 - 09:00]                        ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

#### 2.4.2 跨设备拖拽交互

场景编辑页支持跨设备拖拽编排，用户可将设备卡片从底部列表拖入执行区：

- **拖拽源**：设备列表卡片（`DeviceCard`），提供 `dragData` 附加元数据
- **拖拽目标**：执行动作编辑区（`DropTarget`），接收设备 ID 和操作类型
- **鸿蒙 API**：`@ohos.dragEvent` 拖拽事件体系（详见第 4 章）

```typescript
// 设备卡片 — 设置为拖拽源
DeviceCard({ device: this.device })
  .draggable(true)
  .onDragStart((event: DragEvent) => {
    event.setData({
      deviceId: this.device.id,
      deviceType: this.device.type
    });
  })

// 执行动作编辑区 — 设置为拖拽目标
DropTarget()
  .onDrop((event: DragEvent) => {
    const data = event.getData();
    this.actionList.push({
      deviceId: data.deviceId,
      action: 'turnOn'
    });
  })
```

---

### 2.5 个人中心（Profile）

#### 2.5.1 页面结构

```
┌─────────────────────────────────────────────┐
│             个人中心                         │
├─────────────────────────────────────────────┤
│         ┌──────────┐                       │
│         │  头像    │                       │
│         └──────────┘                       │
│           张三丰                           │
│         zhangsan@example.com               │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐│
│  │  👤 账户信息                           ││
│  ├─────────────────────────────────────────┤│
│  │  🔔 消息通知设置                        ││
│  ├─────────────────────────────────────────┤│
│  │  🌐 设备共享                           ││
│  ├─────────────────────────────────────────┤│
│  │  🔒 隐私与安全                          ││
│  ├─────────────────────────────────────────┤│
│  │  ⚙️ 应用设置                            ││
│  ├─────────────────────────────────────────┤│
│  │  📊 能耗统计                            ││
│  ├─────────────────────────────────────────┤│
│  │  ❓ 帮助与反馈                          ││
│  ├─────────────────────────────────────────┤│
│  │  ℹ️ 关于我们                            ││
│  └─────────────────────────────────────────┘│
├─────────────────────────────────────────────┤
│           版本号 v2.1.0 Build 20260604      │
└─────────────────────────────────────────────┘
```

---

### 2.6 能耗统计页（Energy Stats）

#### 2.6.1 页面结构

```
┌─────────────────────────────────────────────┐
│  ← 返回           能耗统计                   │
├─────────────────────────────────────────────┤
│                                             │
│        本月总用电量                          │
│          128.5 kWh                          │
│        较上月 ↓ 12.3%                        │
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │         📈 日用电趋势图（折线）          ││
│  │   峰值出现在 07:00-09:00 和              ││
│  │   19:00-21:00                           ││
│  └─────────────────────────────────────────┘│
│                                             │
│  分类用电（饼图）                            │
│  ┌─────────────────────────────────────────┐│
│  │  空调 45%  ████████████  57.8 kWh      ││
│  │  照明 20%  █████      25.7 kWh          ││
│  │  其他 35%  █████████  45.0 kWh          ││
│  └─────────────────────────────────────────┘│
│                                             │
│  设备排行（柱状图）                          │
│  ┌─────────────────────────────────────────┐│
│  │  ❄️ 客厅空调     ████████████  50.2kWh  ││
│  │  🔌 主卧插座     ██████       28.1kWh   ││
│  │  💡 全屋照明     ████         20.5kWh   ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

---

## 3. 沉浸光感交互设计详解

### 3.1 什么是沉浸光感

沉浸光感（Halo Light Interaction）是 HarmonyOS Design 的标志性交互范式。其核心思想是：**每一个可交互的控件都如同真实物理世界中的发光体，通过光晕、透明度变化、光影层级来传递状态与反馈**。

### 3.2 光感视觉模型

```
┌────────────────────────────────────────────────┐
│                 光感视觉模型                    │
├────────────────────────────────────────────────┤
│                                                │
│        外发光层（Outer Glow / Ambient）        │
│        模糊半径 20-40vp，透明度 20-40%          │
│        颜色随状态语义变化（蓝=激活，绿=成功）   │
│  ┌──────────────────────────────────────────┐  │
│  │           控件主体层（Surface）           │  │
│  │        背景色 + 圆角 + 阴影基础层         │  │
│  │  ┌────────────────────────────────────┐  │  │
│  │  │      内阴影层（Inner Shadow）       │  │  │
│  │  │   顶部亮边 8%→0% 渐变模拟厚度感     │  │  │
│  │  │   底部压暗 0%→8% 渐变模拟立体感     │  │  │
│  │  │                                     │  │  │
│  │  │        ← 内容区（Content）→          │  │  │
│  │  └────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
│                                                │
└────────────────────────────────────────────────┘
```

### 3.3 沉浸光感按键（Immersive Halo Button）设计规格

#### 3.3.1 按键光感状态机

| 状态 | 光感表现 | 参数说明 |
|------|----------|----------|
| **默认态（Default）** | 主体层正常亮度，无光晕 | opacity: 1.0, shadow opacity: 0 |
| **悬停态（Hover）** | 边框产生 10vp 柔和光晕，透明度 20% | hover 时 shadow opacity: 0.2 |
| **按下态（Pressed）** | 光晕收缩至 6vp，向内压缩，透明度 30% | scale: 0.97, shadow blur: 12 |
| **激活态（Active/On）** | 持续外发光，边框光晕 20vp，颜色为品牌色 | shadow opacity: 0.4, duration: 200ms |
| **禁用态（Disabled）** | 整体压暗至 40%，光晕消失 | opacity: 0.4 |

#### 3.3.2 光感层级参数速查

```typescript
// 沉浸光感按钮配置参数
const HaloButtonConfig = {
  // 外发光参数
  glow: {
    default: { blurRadius: 0, color: 'transparent', opacity: 0 },
    hover:   { blurRadius: 10, color: '#007DFF', opacity: 0.2 },
    pressed: { blurRadius: 6, color: '#007DFF', opacity: 0.3 },
    active:  { blurRadius: 20, color: '#007DFF', opacity: 0.4 },
    disabled: { blurRadius: 0, color: 'transparent', opacity: 0 },
  },
  // 内阴影参数（立体感）
  innerShadow: {
    topLight: { offsetY: -1, blurRadius: 2, color: '#FFFFFFFF', opacity: 0.08 },
    bottomDark: { offsetY: 1, blurRadius: 2, color: '#000000', opacity: 0.08 },
  },
  // 动画曲线
  animation: {
    enter: { duration: 200, curve: Curve.EaseOut },
    exit:  { duration: 150, curve: Curve.EaseIn },
  }
};
```

### 3.4 设备开关光感反馈（Device Toggle Halo）

设备开关是智能家居 APP 中最高频的控件，其光感实现需要体现**状态切换的流畅感**：

```typescript
@Component
struct HaloToggle {
  @Link isOn: boolean;
  @State glowOpacity: number = 0;

  build() {
    Stack() {
      // 底层 Track（滑轨）
      Rect()
        .width(52)
        .height(28)
        .fill(this.isOn ? '#007DFF' : '#E6E6E6')
        .radius(14)
        .animation({ duration: 250, curve: Curve.EaseOut })

      // 光感叠加层（核心光感效果）
      Rect()
        .width(52)
        .height(28)
        .fill(
          new LinearGradient({
            direction: GradientDirection.TopToBottom,
            colors: [['#FFFFFFFF', 0.0], ['#00A5FF', 0.3], ['#FFFFFFFF', 0.6]]
          })
        )
        .radius(14)
        .opacity(this.glowOpacity * 0.3) // 光感叠加层
        .clip(true)

      // Thumb（滑块）
      Circle()
        .width(24)
        .height(24)
        .fill('#FFFFFF')
        .shadow({
          radius: 8,
          color: this.isOn ? '#33007DFF' : '#33000000',
          offsetX: 0,
          offsetY: 2
        })
        .translate({ x: this.isOn ? 26 : 2, y: 2 })
        .animation({ duration: 250, curve: Curve.EaseOut })
    }
    .gesture(
      TapGesture()
        .onAction(() => {
          // 切换前产生短暂光感爆发动画
          animateTo({ duration: 100 }, () => {
            this.glowOpacity = 1.0;
          });
          this.isOn = !this.isOn;
          // 切换后光感消退
          animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
            this.glowOpacity = 0.0;
          });
          this.syncState();
        })
    )
  }

  private syncState(): void {
    // 调用设备控制 API 同步状态
  }
}
```

### 3.5 卡片沉浸光感（Card Halo Effect）

设备卡片在首页列表中使用，其光感效果体现在**整体氛围光**和**触控反馈光**：

| 状态 | 视觉表现 | 实现 API |
|------|----------|----------|
| Default | 白色背景 + 浅灰阴影 | `box-shadow: 0 2vp 8vp rgba(0,0,0,0.06)` |
| Hover | 边框产生 `#007DFF` 淡光晕 8vp | `shadow: blur 8, color #33007DFF` |
| Pressed | 整体向下压缩 1vp + 光晕消散 | `transform: scale(0.99)` |
| Active（设备在线） | 左侧 3vp 品牌色光条持续亮起 | 左侧边框渐变色 + opacity 动画 |

```typescript
@Component
struct HaloCard {
  @Prop device: Device;
  @State isPressed: boolean = false;

  build() {
    Column() {
      // ... 设备内容
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: this.isPressed ? 4 : 8,
      color: this.isPressed ? '#22000000' : '#0F000000',
      offsetX: 0,
      offsetY: this.isPressed ? 2 : 4
    })
    .border({
      width: 1,
      color: this.device.online ? '#33007DFF' : '#0F000000',
      radius: 16
    })
    .scale({ x: this.isPressed ? 0.99 : 1, y: this.isPressed ? 0.99 : 1 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .gesture(
      LongPressGesture()
        .onAction(() => { this.isPressed = true; })
        .onActionEnd(() => { this.isPressed = false; })
    )
  }
}
```

---

## 4. 技术接入手册（API 清单）

### 4.1 分类索引

| 分类 | 说明 |
|------|------|
| **图形渲染** | 光感效果、阴影、模糊、渐变 |
| **动画引擎** | 属性动画、手势联动、交互动效 |
| **设备通信** | 智能设备配网、控制指令下发、状态获取 |
| **分布式能力** | 跨设备流转、超级终端、设备发现 |
| **数据管理** | 轻量级存储、用户首选项、分布式数据同步 |
| **安全能力** | 身份认证、权限管理 |
| **UI 组件** | 原生组件库、容器组件 |

---

### 4.2 图形渲染 API

#### 4.2.1 阴影与光晕（ohos.graphics.shadow）

| 接口 | 模块 | 说明 |
|------|------|------|
| `shadow()` | `@ohos.app.ability.Window` | 设置组件阴影，支持 blurRadius / color / offsetX / offsetY |

**核心参数说明：**

```typescript
shadow({
  radius: number,      // 模糊半径（0-100），越大越柔和
  color: string,      // 阴影颜色，支持 rgba 格式
  offsetX: number,    // X 轴偏移
  offsetY: number,    // Y 轴偏移（正值向下）
  type?: ShadowType   // ShadowType.COLOR / ShadowType.BLUR（默认 BLUR）
})
```

**前置条件：** 组件必须支持阴影渲染（如 Column / Row / Stack 容器）
**异常处理：** 若设置 `radius: 0` 则阴影不生效，视觉上等同于无阴影

---

#### 4.2.2 高斯模糊（ohos.graphics.rust）

| 接口 | 模块 | 说明 |
|------|------|------|
| `blur()` | `@ohos.effect` | 高斯模糊效果，可用于实现外发光层 |

> **注意：** 在 ArkUI 中，模糊效果通过 BackgroundFilter 或 Stack 叠加层实现，`blur()` 是装饰性方法，不建议对主内容层使用（影响性能）。

**ArkUI 实现方式：**

```typescript
Stack() {
  // 模糊背景层
  Rect()
    .width('100%')
    .height('100%')
    .backgroundColor('#33007DFF')
    .模糊(20) // 等效 blur(20vp)
}
```

---

#### 4.2.3 渐变色（LinearGradient / RadialGradient）

| 接口 | 模块 | 说明 |
|------|------|------|
| `LinearGradient` | ArkUI 内置 | 线性渐变，用于滑轨、按钮光感渐变 |
| `RadialGradient` | ArkUI 内置 | 径向渐变，用于环形控件的光感效果 |

```typescript
new LinearGradient({
  direction: GradientDirection.Left, // 渐变方向
  colors: [
    ['#007DFF', 0],    // [颜色, 结束位置百分比]
    ['#00A5FF', 1]
  ]
})
```

---

### 4.3 动画引擎 API

#### 4.3.1 属性动画（@ohos.animator）

| 接口 | 说明 |
|------|------|
| `animateTo()` | 声明式属性动画，用于状态切换的隐式动效 |
| `animation()` | 组件级动画配置，直接附加在组件属性上 |

**animateTo 核心参数：**

```typescript
animateTo({
  duration: number,           // 动画时长（毫秒）
  curve: Curve,             // 动画曲线：Curve.EaseOut / EaseIn / FastOutSlowIn 等
  delay?: number,           // 延迟执行（毫秒）
  iterations?: number,       // 重复次数（默认 1）
  playMode?: PlayMode,      // 播放模式：Normal / Reverse / Alternate
}, () => {
  // 动画终点状态变更
  this.value = targetValue;
})
```

**animation 组件级参数：**

```typescript
.animation({
  duration: 200,
  curve: Curve.EaseOut,
  delay: 0,
  iterations: 1,
  playMode: PlayMode.Normal
})
```

---

#### 4.3.2 弹性动画配置（Spring Motion）

| 接口 | 说明 |
|------|------|
| `curves.spring()` | 创建弹性曲线，实现物理真实感动效 |

```typescript
.animateTo(
  {
    duration: 400,
    curve: Curve.Spring({
      response: 0.5,    // 弹簧响应时间（秒）
      dampingFraction: 0.8, // 阻尼系数（越小弹性越大）
      spacing: 0,       // 间距
    })
  },
  () => { /* 状态变更 */ }
)
```

---

#### 4.3.3 页面转场动画

| 接口 | 说明 |
|------|------|
| `router.pushUrl()` with `animation` | 页面转场动画配置 |
| `router.replaceUrl()` | 替换当前页面（无转场） |

```typescript
// 推入新页面，带滑动转场动画
router.pushUrl({
  url: 'pages/DeviceDetail',
  params: { deviceId: 'xxx' }
}, {
  animation: {
    type: animationType.Push,
    duration: 300,
    curve: Curve.FastOutSlowIn
  }
});
```

---

### 4.4 手势识别 API

#### 4.4.1 手势一览

| 手势 | API | 适用场景 |
|------|-----|----------|
| 点击 | `TapGesture` | 按钮触发、开关切换 |
| 长按 | `LongPressGesture` | 设备卡片按压反馈、上下文菜单 |
| 双击 | `DoubleTapGesture` | 全屏展开、快捷操作 |
| 滑动 | `PanGesture` | 亮度/色温调节滑块 |
| 捏合缩放 | `PinchGesture` | 图表缩放、设备卡片放大 |
| 拖拽 | `DragEvent` | 场景编辑跨设备拖拽 |

#### 4.4.2 PanGesture 滑块完整实现

```typescript
PanGesture()
  .onActionStart((event: GestureEvent) => {
    // 记录起始位置
    this.startX = event.localX;
    this.isSliding = true;
  })
  .onActionUpdate((event: GestureEvent) => {
    // 计算偏移量
    const deltaX = event.localX - this.startX;
    const newValue = this.clamp(
      this.min + (this.currentPercent + deltaX / this.trackWidth) * (this.max - this.min),
      this.min,
      this.max
    );
    this.value = newValue;
  })
  .onActionEnd((event: GestureEvent) => {
    this.isSliding = false;
    // 触发设备状态同步
    this.syncToDevice(this.value);
  })
```

---

### 4.5 设备通信 API（智能设备控制）

#### 4.5.1 设备发现与连接

| 接口 | 模块 | 说明 |
|------|------|------|
| `deviceManager.bindDevice()` | `@ohos.distributedhardware.deviceManager` | 绑定分布式设备 |
| `deviceManager.getTrustedDeviceList()` | `@ohos.distributedhardware.deviceManager` | 获取可信设备列表 |
| `deviceManager.checkDeviceManagerStatus()` | `@ohos.distributedhardware.deviceManager` | 检查设备管理器状态 |

**前置条件：**

1. 申请权限 `ohos.permission.DISTRIBUTED_DEVICE_STATE_ACCESS`
2. 用户完成设备配对授权弹窗确认
3. 设备在同一局域网或华为智能家居生态局域网内

**异常处理：**

| 错误码 | 说明 | 处理方案 |
|--------|------|----------|
| `-1` | 设备未发现 | 显示"正在搜索设备..."，自动重试 3 次 |
| `-2` | 设备离线 | 显示离线提示，引导用户检查网络 |
| `-3` | 绑定超时 | 超时提示，提供"重新搜索"按钮 |

---

#### 4.5.2 设备控制指令下发

| 接口 | 模块 | 说明 |
|------|------|------|
| `preferentiaManager.sendCommand()` | `@ohos.distributedhardware.preferentiaManager` | 向智能设备发送控制指令 |
| `deviceStateChange()` | `@ohos.distributedhardware.deviceManager` | 监听设备状态变更 |

**指令格式示例（灯光控制）：**

```typescript
// 发送开灯指令
let cmd = {
  deviceId: 'light_001',
  command: 'setPower',
  params: {
    state: 1,      // 0=关，1=开
    brightness: 80, // 亮度 0-100
    colorTemp: 4000 // 色温 2700-6500
  },
  transType: 1,   // 可靠传输
  priority: 1
};

preferentiaManager.sendCommand(cmd)
  .then(() => {
    // 成功，更新本地状态
    this.deviceState = 'on';
  })
  .catch((err) => {
    // 失败，回退 UI 状态并提示
    this.deviceState = 'off';
    promptAction.showToast({ message: '指令发送失败，请检查设备连接' });
  });
```

**权限配置（module.json5）：**

```json
{
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
      "name": "ohos.permission.INTERNET",
      "reason": "$string:reason_internet",
      "usedScene": {
        "abilities": ["EntryAbility"],
        "when": "always"
      }
    }
  ]
}
```

---

#### 4.5.3 设备状态实时同步

| 接口 | 说明 |
|------|------|
| ` deviceStateChange.on('deviceStateChange', callback)` | 设备状态变更订阅 |
| ` EventHub.on(event)` | 订阅指定事件 |

```typescript
// 在 EntryAbility 或 DeviceManager 中订阅
deviceManager.on('deviceStateChange', (data) => {
  if (data.deviceId === this.deviceId) {
    // 实时更新设备状态
    this.deviceState = data.state;
    // 触发 UI 更新
    this.notifyStateChange();
  }
});

// 页面销毁时取消订阅
aboutToDisappear() {
  deviceManager.off('deviceStateChange');
}
```

---

### 4.6 分布式能力 API（跨设备流转）

#### 4.6.1 分布式数据管理

| 接口 | 说明 |
|------|------|
| `distributedData.createKVManager()` | 创建键值数据库管理器，实现跨设备数据同步 |
| `kvStore.put()` / `kvStore.get()` | 键值存储读写 |
| `kvStore.on('syncComplete')` | 同步完成事件订阅 |

**典型场景：** 用户在手机上调整了"回家模式"场景，期望同步到平板上的 APP 界面：

```typescript
import distributedKVStore from '@ohos.data.distributedKVStore';

let kvManager = distributedKVStore.createKVManager({
  context: this.context,
  bundleName: 'com.smarthome.aihub'
});

kvManager.getKVStore('device_state_store', (err, kvStore) => {
  // 写入设备状态
  kvStore.put('scene_mode', 'home', (err) => {
    if (!err) {
      // 数据同步到其他设备
      kvStore.sync('SYNCHRONIZE_RETAIN');
    }
  });
});
```

---

#### 4.6.2 跨设备拖拽流转

| 接口 | 说明 |
|------|------|
| `setDragData()` | 设置拖拽数据元信息 |
| `onDrop()` | 接收端接收拖拽数据 |
| `want-agent` | 拖拽目标跨设备解析 |

```typescript
// 拖拽发起端（手机）
.onDragStart((event: DragEvent) => {
  event.setData({
    'deviceAction': JSON.stringify({
      deviceId: this.device.id,
      action: 'turnOn',
      params: { brightness: 80 }
    }),
    'dragFlag': 'cross_device'
  });
  // 指定流转目标：同局域网内所有可信设备
  event.setDragDpid('SAME_NETWORK');
})

// 拖拽接收端（智慧屏）
.onDrop((event: DragEvent) => {
  const rawData = event.getData();
  const action = JSON.parse(rawData['deviceAction']);
  // 在智慧屏上执行对应动作
  this.executeActionOnTV(action);
})
```

---

### 4.7 UI 组件库 API

#### 4.7.1 基础组件

| 组件 | 说明 | 关键属性 |
|------|------|----------|
| `Button` | 按钮，支持胶囊/圆形/文本类型 | `type: ButtonType`, `stateEffect: boolean` |
| `Toggle` | 开关组件，自带光感动效 | `type: ToggleType.Switch`, `isOn: boolean` |
| `Slider` | 滑块（原生），需配合自定义光感 | `value: number`, `min: number`, `max: number` |
| `TextField` | 文本输入，搜索/表单场景 | `placeholder`, `controller` |
| `List` | 列表容器，长列表渲染优化 | `cachedCount`, `repeatSign` |

#### 4.7.2 容器与布局

| 组件 | 说明 |
|------|------|
| `Row` / `Column` | 线性布局 |
| `Stack` | 层叠布局（光感叠加层必备） |
| `Grid` / `GridItem` | 网格布局（场景图标排列） |
| `List` / `ListItem` | 列表容器 |

#### 4.7.3 自适应布局 API

| 接口 | 说明 |
|------|------|
| `display.getAllDisplays()` | 获取所有已连接屏幕信息 |
| `display.getDefaultDisplay()` | 获取当前设备主屏幕 |
| `length` 单位：`vp` / `px` / `fp` | 视觉像素 / 物理像素 / 灵活像素 |
| `ConstraintSize` | 约束尺寸，配合 `maxWidth` / `minWidth` 实现响应式 |

---

### 4.8 权限与安全 API

| 权限名称 | 用途 | 申请方式 |
|----------|------|----------|
| `ohos.permission.DISTRIBUTED_DEVICE_STATE_ACCESS` | 访问分布式设备状态 | 用户授权（inuse 场景） |
| `ohos.permission.INTERNET` | 网络通信（设备配网） | 自动授予 |
| `ohos.permission.LOCATION` | 位置权限（地理围栏自动化） | 用户授权（always 场景） |
| `ohos.permission.CAMERA` | 扫码配网场景 | 用户授权（inuse 场景） |

---

### 4.9 API 调用异常处理汇总

| 场景 | 异常表现 | 处理策略 |
|------|----------|----------|
| 设备未发现 | 指令发送无响应 | 启动 5 秒超时定时器，超时后提示"设备离线" |
| 网络不稳定 | 指令发送失败 | 本地缓存指令，网络恢复后自动重发（最多重试 3 次） |
| 设备不支持指令 | 返回错误码 | 解析错误码，显示"该设备不支持此操作" |
| 权限不足 | 弹窗被拒绝 | 引导用户前往"设置 > 权限管理"开启 |
| 多设备竞争 | 状态不一致 | 以服务器返回状态为准，本地状态覆盖 |

---

## 5. 跨设备形态适配逻辑

### 5.1 设备形态速查

| 设备形态 | 典型屏幕尺寸 | 核心适配策略 |
|----------|--------------|--------------|
| 手机 | 360×780 ~ 428×926 vp | 单列布局为主，底部 Tab 导航 |
| 平板 | 600vp+ 宽度 | 双栏布局（左侧设备列表，右侧详情） |
| 智慧屏 | 1920×1080 ~ 3840×2160 | 大字号 + 横向焦点导航 + 远距离触控 |
| 智能手表 | 屏幕小（圆屏/方屏） | 简化列表 + 表盘卡片式 + 旋钮交互 |

### 5.2 自适应布局 API 使用

#### 5.2.1 资源限定符（Resource Qualifiers）

鸿蒙支持基于屏幕尺寸的**资源限定符**机制，自动加载对应布局：

```
/entry/src/main/resources/
  ├── base/
  │   └── layout/
  │       └── home_page.xml          # 默认布局
  ├── zh_CN/
  │   └── layout/
  │       └── home_page.xml          # 中文语言
  ├── 768vp/                         # 平板适配
  │   └── layout/
  │       └── home_page.xml
  └── watch_circular/               # 圆形手表
      └── layout/
          └── home_page.xml
```

#### 5.2.2 布局配置示例

**手机（默认）/ 平板（双栏）：**

```xml
<!-- base/layout/home_page.xml -->
<DirectionalLayout
  ohos:width="match_parent"
  ohos:height="match_parent"
  ohos:orientation="vertical">

  <SceneQuickAccessList
    ohos:width="match_parent"
    ohos:height="120vp" />

  <DeviceList
    ohos:width="match_parent"
    ohos:height="0xp"
    ohos:layout_alignment="1" /> <!-- layout_alignment=1 表示 weight -->
</DirectionalLayout>

<!-- 768vp/layout/home_page.xml（平板） -->
<DirectionalLayout
  ohos:width="match_parent"
  ohos:height="match_parent"
  ohos:orientation="horizontal">

  <DeviceList
    ohos:width="320vp"
    ohos:height="match_parent" />

  <DeviceDetail
    ohos:width="0xp"
    ohos:layout_alignment="1"
    ohos:layout_weight="1" />
</DirectionalLayout>
```

#### 5.2.3 ArkUI 条件渲染适配

```typescript
@Entry
@Component
struct HomePage {
  @State windowWidth: number = 360;

  aboutToAppear() {
    // 获取当前屏幕宽度
    window.getPreferredWidth(window.getLastWindow().getRootWindowId(), (w) => {
      this.windowWidth = px2vp(w);
    });
  }

  build() {
    if (this.windowWidth >= 600) {
      // 平板：双栏布局
      this.buildTabletLayout();
    } else if (this.windowWidth >= 200) {
      // 手机：单列布局
      this.buildPhoneLayout();
    } else {
      // 手表：卡片流
      this.buildWatchLayout();
    }
  }
}
```

### 5.3 智慧屏特殊适配

| 适配点 | 规格 |
|--------|------|
| 触控热区 | 最小 64vp × 64vp（远距离触控需要更大热区） |
| 字体大小 | 最小 Title 不低于 36vp，正文不低于 24vp |
| 焦点导航 | 支持四向/八向焦点导航，使用 `focusable(true)` + `focusBorder` |
| 交互方式 | 遥控器方向键 + 确认键为主，遥控器手势（滑动）为辅 |
| 滚动速度 | 遥控器滚动步长增大，每步至少滚动一屏的 1/4 |

**焦点边框光感配置：**

```typescript
Text('设备名称')
  .focusable(true)
  .focusBorder({
    width: 3,
    color: '#007DFF',
    radius: 12,
    style: FocusBorderStyle.OUTLINE
  })
  .onFocus(() => {
    // 获得焦点时的光感效果
    animateTo({ duration: 200 }, () => {
      this.focused = true;
    });
  })
```

---

## 6. 差异化设计要点

### 6.1 鸿蒙 vs. Android / iOS 核心差异

| 维度 | 鸿蒙（HarmonyOS） | Android | iOS |
|------|-------------------|---------|-----|
| **UI 框架** | ArkUI（声明式） | Jetpack Compose（声明式）/ View 系统 | SwiftUI（声明式） |
| **开发语言** | ArkTS（TypeScript 超集） | Kotlin / Java | Swift |
| **包格式** | HAP（HarmsonyOS Ability Package） | APK | IPA |
| **跨设备协同** | 分布式软总线，设备间无缝流转 | 无原生支持（依赖第三方框架） | AirDrop（有限场景） |
| **原子化服务** | 服务卡片（Service Widget），无需安装 APP | Widget（桌面小部件） | Widget（锁屏小组件） |
| **动效哲学** | 光感 + 弹性物理动效，强调"活的"界面 | Material You 动效，强调涟漪反馈 | 毛玻璃 + 弹性动效，强调流畅 |
| **数据管理** | 分布式 KVStore，跨设备同步开箱即用 | SharedPreferences / Room | UserDefaults / CoreData |
| **安全模型** | 权限粒度更细，首次启动即弹窗授权 | 运行时权限（危险权限） | ATT 追踪提示（iOS 14+） |

### 6.2 沉浸光感的差异化实现

**Android 方案：** 依赖 XML drawable + StateListDrawable 实现selector效果，光感依赖 XML shape 叠加，渲染效率低，且无法动态响应手势。

**iOS 方案：** 使用 UIButton 的 tintColor + backgroundColor 叠加，或 CALayer shadowPath，动画需要手动管理 CADisplayLink。

**鸿蒙方案：** 声明式统一 API，状态变更天然驱动动画，光感参数与布局参数同一套 `@State` 驱动，代码量减少约 60%：

```typescript
// Android：需要额外 custom drawable 配合 ObjectAnimator
// iOS：需要 CADisplayLink 手动刷新
// 鸿蒙：状态驱动动画（声明式）
@State isPressed: boolean = false;
.animateTo(
  { duration: 150 },
  () => { this.isPressed = true; }
)
.shadow({
  radius: this.isPressed ? 4 : 12,
  color: '#33007DFF'
})
```

### 6.3 跨设备流转的差异化优势

| 能力 | 鸿蒙 | Android | iOS |
|------|------|---------|-----|
| 跨设备 UI 流转 | 原生 `dragEvent` 跨设备 | 需要自研 | 需要自研 |
| 设备发现 | 软总线自动发现 | 需要手动配对 | 需要手动配对 |
| 数据同步 | 分布式 KVStore 自动同步 | 需要手动同步 | 需要手动同步 |
| 协同算力 | 设备间算力可动态组合 | 不支持 | 不支持 |
| 典型场景 | 手机控制电视播放，手机碰平板流转操控 | — | — |

### 6.4 场景化推荐实现

| 场景 | 鸿蒙实现路径 |
|------|-------------|
| 用户回家自动开灯 | `geoFence` 地理围栏 + `deviceManager.checkDeviceManagerStatus` + `preferentiaManager.sendCommand` |
| 手机碰平板流转控制 | `want-agent` 流转协议 + `onDrop` 跨设备接收 + `deviceStateChange` 状态同步 |
| 智慧屏远程调设备 | `remoteDeviceId` 远程设备调用 + `deviceManager.getTrustedDeviceList` 设备发现 |
| 设备状态跨设备同步 | `distributedKVStore` + `sync(SYNCHRONIZE_RETAIN)` |

---

## 📄 附录

### A. HAP 包开发规范速查

| 规范 | 说明 |
|------|------|
| **Stage 模型** | 必须是 Stage 模型（不支持 FA 模型） |
| **入口 Ability** | EntryAbility 作为应用主入口 |
| **页面路由** | 通过 `router.pushUrl` / `router.replaceUrl` 导航 |
| **资源管理** | 资源放在 `resources/` 目录下，按限定符分类 |
| **权限配置** | 在 `module.json5` 的 `requestPermissions` 中声明 |
| **签名配置** | 发布前需要配置华为AGC签名指纹 |

### B. 开发工具链

| 工具 | 用途 |
|------|------|
| **DevEco Studio 5.0+** | 官方 IDE，支持 ArkTS 代码编辑、预览、调试 |
| **ArkUI Inspector** | 可视化 UI 结构查看与属性编辑 |
| **HiProfiler** | 性能分析工具，卡顿/帧率监控 |
| **hdc** | 设备连接调试工具（命令行） |
| **bm bundle** | HAP 包管理命令行工具 |

### C. 参考文档

- [HarmonyOS Design 官方规范](https://developer.huawei.com/consumer/cn/design/harmonyos-design)
- [ArkUI 组件参考](https://developer.huawei.com/consumer/cn/arkuits)
- [分布式能力开发指南](https://developer.huawei.com/consumer/cn/doc/guide)
- [DevEco Studio 使用指南](https://developer.huawei.com/consumer/cn/deveco-studio)

---

> **文档维护说明：** 本文档为初版设计文档，随着 HarmonyOS 版本迭代，应定期更新 API 清单及设计规范适配点。建议在每个里程碑版本发布后 2 周内完成文档同步更新。