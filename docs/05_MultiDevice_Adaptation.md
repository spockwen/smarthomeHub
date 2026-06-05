# Phase 5：多设备形态适配指南

> **本文档版本：** v1.0  
> **编制日期：** 2026-06-04  
> **适配系统：** HarmonyOS 4.0+（NEXT / Dev Eco Studio 5.0+）  
> **所属项目：** SmartHome AIHub 鸿蒙全页面重构设计

---

## 📋 目录

1. [设备形态概览](#1-设备形态概览)
2. [资源限定符适配机制](#2-资源限定符适配机制)
3. [手机适配（默认）](#3-手机适配默认)
4. [平板适配（双栏布局）](#4-平板适配双栏布局)
5. [智慧屏适配（大屏交互）](#5-智慧屏适配大屏交互)
6. [智能手表适配（手表端）](#6-智能手表适配手表端)
7. [ArkUI 条件渲染适配](#7-arkui-条件渲染适配)
8. [多端组件差异速查](#8-多端组件差异速查)

---

## 1. 设备形态概览

### 1.1 形态分类与屏幕规格

| 设备形态 | 典型屏幕尺寸（vp） | 设计分辨率 | 底部导航 | 触控热区最小尺寸 |
|----------|-----------------|-----------|---------|----------------|
| **手机** | 360×780 ~ 428×926 | 393×851 | TabBar | 44×44vp |
| **平板** | 600×1024 ~ 1366×1024 | 800×1280 | TabBar | 44×44vp |
| **智慧屏** | 1920×1080 ~ 3840×2160 | 1920×1080 | 无（遥控器） | 64×64vp |
| **智能手表** | 圆形 180-220 / 方屏 240×280 | 454×454（圆屏） | 旋钮/语音 | 40×40vp |

### 1.2 核心适配策略

```
┌────────────────────────────────────────────────────────────┐
│                   形态适配策略总览                         │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  手机 ────► 单列纵向布局 + 底部 TabBar                       │
│           场景：快速查看 / 随手控制                          │
│                                                              │
│  平板 ────► 双栏布局（Master-Detail）                       │
│           左栏设备列表 / 右栏设备详情                        │
│           场景：横屏手持 / 桌面放置                          │
│                                                              │
│  智慧屏 ───► 大字号 + 横向焦点导航 + 远距离触控              │
│           遥控器四向导航 / 大区块操作                        │
│           场景：客厅C位 / 远距离观看操控                     │
│                                                              │
│  手表 ────► 简化列表 + 表盘卡片 + 旋钮交互                   │
│           语音输入 / 单手操作                               │
│           场景：单手快速查看 / 抬手操控                      │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

### 1.3 各形态核心差异

| 维度 | 手机 | 平板 | 智慧屏 | 手表 |
|------|------|------|--------|------|
| **布局模式** | 单列 | 双栏 | 大屏单列 | 单列/卡片流 |
| **导航方式** | 触控 + TabBar | 触控 + TabBar | 遥控器四向 + 确认 | 旋钮 + 语音 |
| **字号基准** | 16vp | 18vp | 36vp（≥） | 12vp |
| **设备图标** | 48×48 | 64×64 | 96×96 | 32×32 |
| **滑块触控** | 44vp 热区 | 44vp 热区 | 96vp 热区 | 旋钮控制 |
| **页面转场** | 滑动 | 滑动/渐变 | 淡入淡出 | 无转场 |
| **动效复杂度** | 完整 | 完整 | 简化（性能优先） | 极简 |

---

## 2. 资源限定符适配机制

### 2.1 资源目录结构

鸿蒙通过 **资源限定符（Resource Qualifiers）** 实现多端自动适配。在 `entry/src/main/resources/` 下创建以下目录结构：

```
resources/
├── base/
│   ├── layout/              ← 默认布局（手机）
│   │   ├── home_page.xml
│   │   ├── device_detail.xml
│   │   ├── scene_editor.xml
│   │   ├── profile.xml
│   │   └── energy_stats.xml
│   ├── element/             ← 默认元素
│   │   ├── color.json
│   │   ├── font.json
│   │   └── string.json
│   └── media/               ← 默认媒体资源
│       ├── icon_home.png
│       └── icon_device.png
│
├── 768vp/                   ← 平板适配（宽度 ≥ 768vp）
│   ├── layout/
│   │   ├── home_page.xml    ← 覆盖：双栏布局
│   │   └── device_detail.xml
│   ├── element/
│   │   └── font.json        ← 覆盖：字号放大
│   └── media/
│
├── 1080tv/                  ← 智慧屏适配（1080tv 分辨率）
│   ├── layout/
│   │   ├── home_page.xml    ← 覆盖：大字号 + 简化布局
│   │   └── device_detail.xml
│   ├── element/
│   │   ├── color.json
│   │   └── font.json        ← 覆盖：字号进一步放大
│   └── media/
│       └── icon_home.png    ← 覆盖：大尺寸图标
│
├── watch_circular/          ← 圆形智能手表
│   ├── layout/
│   │   └── home_page.xml    ← 覆盖：圆形裁剪适配
│   └── media/
│
├── watch_square/            ← 方屏智能手表
│   ├── layout/
│   │   └── home_page.xml
│   └── media/
│
└── zh_CN/                   ← 中文语言（可与尺寸限定符叠加）
    ├── element/
    │   └── string.json
    └── layout/
```

### 2.2 限定符优先级

资源限定符按照以下优先级生效（越靠前越优先）：

```
1. 屏幕尺寸限定符（768vp / 1080tv）  > 默认
2. 屏幕密度限定符（xxldpi / xhdpi）  > 默认
3. 语言限定符（zh_CN / en_US）       > 默认
4. 设备类型限定符（watch_circular）  > 默认
```

**叠加示例：** `768vp + zh_CN` → `resources/768vp/zh_CN/`

### 2.3 布局 XML 适配示例

**手机默认布局（base/layout/home_page.xml）：**

```xml
<DirectionalLayout
  ohos:width="match_parent"
  ohos:height="match_parent"
  ohos:orientation="vertical">

  <!-- 顶部问候区 -->
  <FrameLayout
    ohos:width="match_parent"
    ohos:height="64vp"
    ohos:id="$+id/header" />

  <!-- 环境信息卡片 -->
  <FrameLayout
    ohos:width="match_parent"
    ohos:height="100vp"
    ohos:id="$+id/env_card" />

  <!-- 快捷场景（横向滚动） -->
  <FrameLayout
    ohos:width="match_parent"
    ohos:height="140vp"
    ohos:id="$+id/scene_row" />

  <!-- 设备列表（占据剩余空间） -->
  <Scroll
    ohos:width="match_parent"
    ohos:height="0vp"
    ohos:layout_alignment="1"
    ohos:id="$+id/device_list" />

</DirectionalLayout>
```

**平板双栏布局覆盖（768vp/layout/home_page.xml）：**

```xml
<DirectionalLayout
  ohos:width="match_parent"
  ohos:height="match_parent"
  ohos:orientation="horizontal">

  <!-- 左侧设备列表（固定宽度） -->
  <Scroll
    ohos:width="360vp"
    ohos:height="match_parent"
    ohos:id="$+id/device_list">

    <!-- 列表内容（与手机相同结构） -->
    <FrameLayout
      ohos:width="match_parent"
      ohos:height="64vp" />

    <FrameLayout
      ohos:width="match_parent"
      ohos:height="100vp" />

    <Scroll
      ohos:width="match_parent"
      ohos:height="140vp" />

  </Scroll>

  <!-- 右侧设备详情（占据剩余空间） -->
  <FrameLayout
    ohos:width="0vp"
    ohos:layout_alignment="1"
    ohos:layout_weight="1"
    ohos:id="$+id/device_detail" />

</DirectionalLayout>
```

---

## 3. 手机适配（默认）

### 3.1 页面布局特点

手机作为默认适配目标，采用单列纵向滚动布局：

```
┌────────────────────────┐
│    状态栏（系统级）     │
├────────────────────────┤
│   顶部区域 64vp         │
│   问候语 + 通知入口      │
├────────────────────────┤
│                        │
│  环境信息卡片           │
│  100vp                 │
│                        │
├────────────────────────┤
│                        │
│  快捷场景（横向滚动）    │
│  140vp                 │
│                        │
├────────────────────────┤
│                        │
│  设备列表（滚动）       │
│  layout_weight=1       │
│                        │
│                        │
│                        │
├────────────────────────┤
│  底部 TabBar 56vp      │
└────────────────────────┘
```

### 3.2 ArkUI 代码结构

```typescript
@Entry
@Component
struct HomePagePhone {
  @State deviceList: Device[] = [];
  @State sceneList: Scene[] = [];

  build() {
    Column() {
      // 顶部问候区
      this.buildHeader()

      Scroll() {
        Column() {
          this.buildEnvironmentCard()  // 100vp
          this.buildSceneRow()         // 140vp
          this.buildDeviceList()       // flex-grow
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
```

### 3.3 触控热区配置

| 组件 | 热区尺寸 | 实现方式 |
|------|---------|---------|
| 设备列表项 | 72vp 高度，宽度 100% | min-height 44vp |
| 场景卡片 | 120×120vp（热区 44×44vp 内） | padding 调整 |
| 开关 Toggle | 系统默认（52×28vp） | 热区通过父容器 padding 扩大 |
| FAB 按钮 | 56×56vp | min-width/min-height 44vp |

---

## 4. 平板适配（双栏布局）

### 4.1 页面布局特点

平板采用 Master-Detail 双栏布局，设备列表在左，设备详情在右：

```
┌─────────────────────────────────────────────────────────┐
│              状态栏（系统级）                            │
├────────────────────────┬────────────────────────────────┤
│                        │                                │
│  设备列表              │     设备详情                    │
│  360vp（固定）         │     layout_weight=1            │
│                        │                                │
│  ┌──────────────────┐ │  ┌──────────────────────────┐  │
│  │ 环境信息卡片     │ │  │                          │  │
│  └──────────────────┘ │  │     设备大图标            │  │
│                        │  │     （200×200）           │  │
│  快捷场景（横向滚动）  │  │                          │  │
│  140vp                 │  │     控制面板              │  │
│                        │  │     亮度 / 色温 / 情景    │  │
│  设备列表（滚动）      │  │                          │  │
│                        │  │     设备信息卡片          │  │
│                        │  │                          │  │
│                        │  └──────────────────────────┘  │
│                        │                                │
├────────────────────────┴────────────────────────────────┤
│              底部 TabBar 56vp                            │
└─────────────────────────────────────────────────────────┘
```

### 4.2 双栏 ArkUI 实现

```typescript
@Entry
@Component
struct HomePageTablet {
  @State selectedDevice: Device | null = null;

  build() {
    Row() {
      // 左侧：设备列表
      Column() {
        this.buildEnvironmentCard()
        this.buildSceneRow()
        this.buildDeviceList()
      }
      .width(360)
      .height('100%')

      // 右侧：设备详情（初始显示占位）
      if (this.selectedDevice) {
        DeviceDetailPanel({ device: this.selectedDevice })
          .layoutWeight(1)
      } else {
        PlaceholderPanel()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildDeviceList() {
    Scroll() {
      Column() {
        ForEach(this.deviceList, (device: Device) => {
          DeviceListItem({ device: device })
            .onClick(() => {
              this.selectedDevice = device;
            })
            .backgroundColor(
              this.selectedDevice?.id === device.id ? '#F0F5F7' : 'transparent'
            )
        })
      }
    }
    .layoutWeight(1)
  }
}
```

### 4.3 平板特有 UI 调整

| 调整项 | 手机 | 平板 |
|--------|------|------|
| 设备卡片高度 | 72vp | 80vp |
| 设备图标尺寸 | 48×48 | 56×56 |
| 滑块轨道宽度 | 100% | 80%（居中） |
| 情景模式按钮布局 | 4列 | 6列 |
| 底部 TabBar 图标 | 24×24 | 28×28 |
| TabBar 标签字号 | 10vp | 12vp |

---

## 5. 智慧屏适配（大屏交互）

### 5.1 页面布局特点

智慧屏面向远距离操控（遥控器距离 2-5 米），采用大字号、高对比度、横向大区块布局：

```
┌─────────────────────────────────────────────────────────┐
│                    状态栏（系统级）                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │                                                  │   │
│  │              顶部问候语（Display 36vp）          │   │
│  │              "张三，您好"                        │   │
│  │              "今日设备运行正常"                  │   │
│  │                                                  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌────────────────┐ ┌────────────────┐ ┌───────────┐ │
│  │                │ │                │ │           │ │
│  │    环境信息     │ │    快捷场景     │ │   能耗    │ │
│  │   （横向三等分）│ │   （横向滚动）  │ │  统计    │ │
│  │                │ │                │ │           │ │
│  │    96×96 图标   │ │   设备列表     │ │           │ │
│  │                │ │                │ │           │ │
│  └────────────────┘ └────────────────┘ └───────────┘ │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │                                                  │   │
│  │              设备列表（横向滚动，大卡片）          │   │
│  │              每卡片 200×200vp                     │   │
│  │              触控热区 64×64vp                     │   │
│  │                                                  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  [首页]   [场景]   [设备]   [我的]  ← TabBar    │   │
│  └──────────────────────────────────────────────────┘   │
│                    底部 64vp（误触保护区）                │
└─────────────────────────────────────────────────────────┘
```

### 5.2 焦点导航配置

智慧屏的核心交互是遥控器四向焦点导航，需对可聚焦组件配置 `focusable`：

```typescript
// 焦点配置
Button('设备控制')
  .focusable(true)                    // 允许聚焦
  .focusBorder({
    width: 3,                         // 焦点框宽度
    color: '#007DFF',                 // 焦点框颜色
    radius: 12,                       // 焦点框圆角
    style: FocusBorderStyle.OUTLINE   // OUTLINE=外框，CONTENT=填充
  })
  .onFocus(() => {
    // 获得焦点时触发光感效果
    animateTo({ duration: 200 }, () => {
      this.hasFocus = true;
      this.glowOpacity = 0.3;
    });
  })
  .onBlur(() => {
    // 失去焦点
    animateTo({ duration: 150 }, () => {
      this.hasFocus = false;
      this.glowOpacity = 0;
    });
  })
```

**焦点导航方向映射：**

| 遥控器按键 | 焦点的自然移动方向 |
|-----------|------------------|
| 上 | 向上寻找最近的同列可聚焦组件 |
| 下 | 向下寻找最近的同列可聚焦组件 |
| 左 | 向左寻找最近的同排可聚焦组件 |
| 右 | 向右寻找最近的同排可聚焦组件 |

### 5.3 智慧屏字号与间距规格

| 元素 | 手机字号 | 智慧屏字号 | 放大倍数 |
|------|---------|-----------|---------|
| Display | 36vp | 60vp | 1.67× |
| Title 1 | 28vp | 48vp | 1.71× |
| Title 2 | 22vp | 36vp | 1.64× |
| Body | 16vp | 28vp | 1.75× |
| Caption | 12vp | 20vp | 1.67× |

| 间距 | 手机 | 智慧屏 |
|------|------|--------|
| 页面左右安全边距 | 16vp | 48vp |
| 页面上下安全边距 | 24vp / 64vp | 32vp / 80vp |
| 区块间间距 | 16vp | 32vp |
| 列表项高度 | 72vp | 120vp |

### 5.4 遥控器手势支持

| 手势 | 适用场景 | 实现方式 |
|------|---------|---------|
| 单击确认 | 按钮点击、列表项选择 | `onClick` / `onTap` |
| 双击 | 全屏/详情展开 | `DoubleTapGesture` |
| 滑动（方向键） | 页面滚动、列表滑动 | 方向键自动映射到滚动 |
| 长按 | 右键菜单、快捷操作 | `LongPressGesture` |
| 滑块拖动 | 亮度/色温调节 | PanGesture + 大触控热区 |

---

## 6. 智能手表适配（手表端）

### 6.1 页面布局特点

智能手表屏幕极小，采用极简卡片流 + 旋钮滚动：

```
┌─────────────────────┐
│  ┌───────────────┐  │
│  │  首页快捷入口  │  │
│  │  🏠 回家      │  │
│  │  🌙 睡眠      │  │
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │   设备状态    │  │
│  │  💡 客厅灯:开 │  │
│  │  ❄️ 空调:关   │  │
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │   能耗:2.1kWh │  │
│  └───────────────┘  │
│        ◎            │
│   （旋钮滚动）       │
└─────────────────────┘
```

### 6.2 手表端特殊交互

**旋钮交互（Rotary Knob）：**

```typescript
@State scrollY: number = 0;

Stack() {
  // 手表内容
  Scroll() {
    Column() {
      // ...
    }
  }

  // 旋钮事件监听（通过手势实现）
  GestureLayer() {
    RotationGesture()
      .onAction((event: GestureEvent) => {
        // 旋钮每格旋转约 15 度
        const delta = event.angle / 15; // 换算为滚动步数
        this.scrollY += delta * 60;    // 每步滚动 60vp
      })
  }
}
```

**语音输入入口：**

```typescript
Button()
  .type(ButtonType.Circle)
  .width(56)
  .height(56)
  .backgroundColor('#007DFF')
  .shadow({ radius: 8, color: '#33007DFF' })
  .onClick(() => {
    // 启动语音助手
    inputMethodSystem.on('voiceInput', (text) => {
      this.parseVoiceCommand(text);
    });
  })
```

### 6.3 手表端组件差异

| 组件 | 手机/平板 | 手表 | 说明 |
|------|---------|------|------|
| TabBar | 底部 4 项 | 无 | 手表仅支持单页 |
| 设备列表 | 竖向滚动 | 旋钮滚动 | 旋钮控制 scrollY |
| 场景卡片 | 120×120 | 80×80 | 简化尺寸 |
| 设备详情 | 完整面板 | 单卡片覆盖 | 卡片全屏展示 |
| 滑块调节 | 触控拖动 | 旋钮+确认 | 长按滑块后旋钮调节 |
| 能耗图表 | 折线/饼图 | 纯数字 | 手表不渲染复杂图表 |

---

## 7. ArkUI 条件渲染适配

### 7.1 基于窗口宽度的条件渲染

```typescript
@Entry
@Component
struct HomePageAdaptive {
  @State windowWidth: number = 360;

  aboutToAppear() {
    // 获取当前窗口宽度
    window.getLastWindow().getProperties({
      onSuccess: (windowProperties) => {
        this.windowWidth = px2vp(windowProperties.windowRect.width);
      }
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

### 7.2 基于设备类型的条件渲染

```typescript
import deviceInfo from '@ohos.deviceInfo';

// 获取设备类型
const deviceType = deviceInfo.deviceType; // 'phone' | 'tablet' | 'tv' | 'wearable'

Column() {
  if (deviceType === 'wearable') {
    this.buildWatchCard();
  } else if (deviceType === 'tv') {
    this.buildTVLayout();
  } else {
    this.buildPhoneLayout();
  }
}
```

### 7.3 媒体查询（@ohos.mediaquery）

```typescript
import mediaquery from '@ohos.mediaquery';

@State portraitCallback: boolean = false;

aboutToAppear() {
  // 监听媒体查询变化
  this.listener = mediaquery.matchMediaSync('(orientation: portrait)');
  this.listener.on('change', (result) => {
    this.portraitCallback = result.matches;
  });
}

build() {
  if (this.portraitCallback) {
    // 竖屏布局
    this.buildPortraitLayout();
  } else {
    // 横屏布局
    this.buildLandscapeLayout();
  }
}

aboutToDisappear() {
  // 取消监听
  this.listener.off('change');
}
```

---

## 8. 多端组件差异速查

### 8.1 组件适配总表

| 组件 | 手机 | 平板 | 智慧屏 | 手表 | 适配说明 |
|------|------|------|--------|------|---------|
| `Button` | ✓ | ✓ | ✓ | ✓ | 大字号版智慧屏需配置 `fontSize` |
| `Toggle` | ✓ | ✓ | ✓ | 简化 | 手表仅支持 Switch |
| `Slider` | ✓ | ✓ | ✓ | 旋钮 | 手表用旋钮替代滑动 |
| `List / ListItem` | ✓ | ✓ | ✓ | 简化 | 手表减少列表项内容 |
| `TabBar` | ✓ | ✓ | ✓ | ✗ | 手表不支持 |
| `Image` | ✓ | ✓ | ✓ | ✓ | 需准备 1x/2x/3x 图标资源 |
| `Text` | ✓ | ✓ | ✓ | ✓ | 字号需按比例放大（智慧屏） |
| `Icon` | ✓ | ✓ | ✓ | ✓ | 智慧屏图标建议 96×96vp |

### 8.2 布局容器适配

| 容器 | 手机 | 平板 | 智慧屏 | 手表 |
|------|------|------|--------|------|
| `Column` | ✓ | ✓ | ✓ | ✓ |
| `Row` | ✓ | ✓ | ✓ | ✓ |
| `Stack` | ✓ | ✓ | ✓ | ✓ |
| `Scroll` | ✓ | ✓ | ✓ | 旋钮替代 |
| `List` | ✓ | ✓ | ✓ | 简化 |
| `Grid` | ✓ | ✓ | ✓ | ✗ |
| `Swiper` | ✓ | ✓ | ✓ | ✗ |

### 8.3 动画适配说明

| 动画类型 | 手机 | 平板 | 智慧屏 | 手表 |
|---------|------|------|--------|------|
| 属性动画 `animateTo` | ✓ | ✓ | ✓ | ✓ |
| 弹性动画 `Spring` | ✓ | ✓ | ✓ | ✓ |
| 页面转场 | 滑动 300ms | 滑动 300ms | 淡入 400ms | ✗ |
| 列表滚动 | 弹性滚动 | 弹性滚动 | 固定步长 | 旋钮步进 |
| 呼吸动画（3s+） | ✓ | ✓ | ✓ | ✗（省电） |
| 光感拖尾动画 | ✓ | ✓ | ✗（简化） | ✗ |

**智慧屏动画优化建议：**

- 避免使用 `blur` 模糊（GPU 负载高）
- 减少阴影层级（至多 1 层）
- 简化渐变复杂度（至多 2 个 colorStop）
- 动画时长可延长 1.3 倍（减少视觉疲劳）

---

## 📄 附录

### A. 各形态推荐开发调试方法

| 形态 | 调试方式 | 说明 |
|------|---------|------|
| 手机 | 真机 USB 调试 / 模拟器 | DevEco Studio 内置模拟器 |
| 平板 | 真机 USB 调试 / 模拟器 | 横屏模拟器 |
| 智慧屏 | TV 模拟器 / DevEco Studio TV 插件 | 支持遥控器事件模拟 |
| 手表 | 手表模拟器 | 支持旋钮事件模拟 |
| 多设备协同 | Super Device 真机协同 | 手机+平板+智慧屏真机联动 |

### B. 图标资源尺寸速查

| 图标尺寸 | 适用场景 |
|---------|---------|
| 24×24vp | 手机 TabBar、列表小图标 |
| 32×32vp | 手机设备图标 |
| 48×48vp | 手机大设备图标、场景图标 |
| 56×56vp | 平板设备图标 |
| 64×64vp | 智慧屏触控热区图标 |
| 96×96vp | 智慧屏大图标（主图标区） |
| 32×32vp | 手表设备图标 |

---

> **文档完结**  
> 
> 至此，SmartHome AIHub 鸿蒙全页面重构设计文档已全部产出，文档矩阵涵盖设计规范、页面设计稿、交互逻辑说明书、技术接入手册、多设备适配指南共 5 个 Phase，全部存放于 `E:\harmonyos\SmartHomeAIHub\docs\` 目录下。汇总版完整文档请参见 `SmartHome_HarmonyOS_Design_Guide.md`。