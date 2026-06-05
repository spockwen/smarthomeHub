# 智能家居 APP 页面设计规范清单

> **本文档版本：** v1.0  
> **编制日期：** 2026-06-04  
> **归属：** SmartHome AIHub 鸿蒙重构设计项目  

---

## 📋 文档结构（分阶段产出物）

本项目设计文档按照开发阶段划分为以下文档矩阵：

| 阶段 | 文档名称 | 文件名 | 状态 |
|------|----------|--------|------|
| **Phase 1** | 全局设计规范与沉浸光感设计说明 | `01_Global_Design_Spec.md` | ⬜ 待产出 |
| **Phase 2** | 页面设计稿（首页/设备详情/场景编辑/个人中心/能耗统计） | `02_Page_Designs.md` | ⬜ 待产出 |
| **Phase 3** | 交互逻辑说明书（手势/动画/跨设备流转） | `03_Interaction_Logic.md` | ⬜ 待产出 |
| **Phase 4** | 技术接入手册（API 清单与调用指南） | `04_Tech_API_Handbook.md` | ⬜ 待产出 |
| **Phase 5** | 多设备形态适配指南（手机/平板/智慧屏/手表） | `05_MultiDevice_Adaptation.md` | ⬜ 待产出 |
| **汇总版** | **全页面重构设计方案（完整版）** | `SmartHome_HarmonyOS_Design_Guide.md` | ✅ 已产出 |

---

## 📖 各阶段文档内容概要

### Phase 1：全局设计规范 `01_Global_Design_Spec.md`

**核心内容：**

- HarmonyOS Design 设计语言（简约 / 自然 / 通透）
- 色彩系统（品牌色 / 功能色 / 背景色 / 文字色）
- 字体规范（字号层级 / 字重 / HarmonyOS Sans）
- 间距系统（4pt 基准网格 / xs/sm/md/lg/xl/xxl）
- 圆角规范（组件级圆角 / 页面级圆角）
- 沉浸光感视觉模型（外发光层 / 控件主体层 / 内阴影层）
- 组件通用光感参数配置
- 状态定义（Default / Hover / Pressed / Active / Disabled）

**预计产出时间：** 开发第 1-2 周

---

### Phase 2：页面设计稿 `02_Page_Designs.md`

**核心内容：**

- 首页（Home）设计稿：设备概览 / 快捷控制 / 环境卡片
- 设备详情页（Device Detail）设计稿：控制面板 / 亮度调节 / 色温调节 / 情景模式
- 场景编辑页（Scene Editor）设计稿：触发条件 / 执行动作编排
- 个人中心（Profile）设计稿：账户信息 / 设置入口
- 能耗统计页（Energy Stats）设计稿：用电趋势图 / 分类饼图 / 设备排行
- 各页面 ArkUI 布局代码示例（简化版）
- 关键控件设计标注（尺寸 / 光感状态 / 触控热区）

**预计产出时间：** 开发第 2-3 周

---

### Phase 3：交互逻辑说明书 `03_Interaction_Logic.md`

**核心内容：**

- 手势交互体系（Tap / LongPress / Pan / Pinch / Drag）
- 弹性滑动动效说明（Spring Motion 参数配置）
- 页面转场动画（push / pop / replace）
- 设备状态切换动效（Toggle 光感扫动效果）
- 跨设备拖拽交互流程（场景编排拖拽 / 设备联动拖拽）
- 沉浸光感按键状态机详解（含时序图）
- 交互异常处理（超时反馈 / 离线降级 / 操作可逆）

**预计产出时间：** 开发第 3-4 周

---

### Phase 4：技术接入手册 `04_Tech_API_Handbook.md`

**核心内容：**

- 图形渲染 API（shadow / blur / LinearGradient）
- 动画引擎 API（animateTo / animation / spring）
- 手势识别 API（PanGesture / DragEvent / LongPressGesture）
- 设备通信 API（deviceManager / preferentiaManager）
- 分布式能力 API（KVStore / dragEvent 跨设备）
- UI 组件库 API（Toggle / Button / Slider / List）
- 权限与安全 API（requestPermissions / grantMode）
- API 异常处理汇总表

**预计产出时间：** 开发第 4-5 周

---

### Phase 5：多设备形态适配指南 `05_MultiDevice_Adaptation.md`

**核心内容：**

- 设备形态速查表（手机 / 平板 / 智慧屏 / 智能手表）
- 资源限定符目录结构（layout qualifiers）
- ArkUI 条件渲染适配（基于 windowWidth 判断）
- 智慧屏特殊适配（触控热区 / 焦点导航 / 遥控器支持）
- 智能手表适配（简化列表 / 旋钮交互 / 表盘卡片）
- 各形态页面模板代码

**预计产出时间：** 开发第 5-6 周

---

## 🗂 文档目录结构

```
E:\harmonyos\SmartHomeAIHub\docs\
├── README.md                              # 本文件（索引）
├── SmartHome_HarmonyOS_Design_Guide.md    # ✅ 汇总版（完整设计文档）
├── 01_Global_Design_Spec.md              # ⬜ Phase 1：全局设计规范
├── 02_Page_Designs.md                    # ⬜ Phase 2：页面设计稿
├── 03_Interaction_Logic.md                # ⬜ Phase 3：交互逻辑说明书
├── 04_Tech_API_Handbook.md               # ⬜ Phase 4：技术接入手册
└── 05_MultiDevice_Adaptation.md          # ⬜ Phase 5：多设备形态适配指南
```

---

## 🚀 快速导航

| 需求 | 跳转到 |
|------|--------|
| 完整设计文档（含所有内容） | `SmartHome_HarmonyOS_Design_Guide.md` |
| 色彩 / 字体 / 间距规范 | Phase 1 文档 |
| 页面 UI 线框图 + ArkUI 示例 | Phase 2 文档 |
| 手势 / 动画 / 光感动效参数 | Phase 3 文档 |
| API 接口清单 / 调用方式 / 异常处理 | Phase 4 文档 |
| 多端适配 / 智慧屏 / 手表布局 | Phase 5 文档 |

---

> **维护说明：** 随着项目推进，各 Phase 文档将逐步产出并更新到对应路径下。汇总版文档将保持与各 Phase 文档的交叉引用一致性。