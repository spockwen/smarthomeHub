// ============================================================
// 场景/自动化卡片组件 - SceneCard.ets
// -----------------------------------------------------------
// 用途：统一定义【智能】页面的场景卡片与自动化卡片样式，
//       所有样式集中维护，SmartPage 只传数据。
// ============================================================
//
// ===== 使用方式 =====
//
// 【场景卡片】
//   SceneCard({
//     scene: {
//       id: 'home', name: '回家模式', icon: '🏠',
//       color: '#FF6B35', desc: '打开灯光、空调、净化器',
//       tags: ['客厅灯→开', '空调→26℃', '净化器→开']
//     },
//     onCardClick: () => { /* 执行场景 */ }
//   })
//
// 【自动化卡片】
//   AutoCard({
//     auto: {
//       id: 'auto_leave', name: '离家自动关灯',
//       icon: '🚪', color: '#FF4D4F',
//       desc: '门锁锁定且无人移动时...',
//       enabled: true, statusText: '运行中'
//     },
//     onToggle: (id) => { /* 开关切换 */ }
//   })
//
// ============================================================
// 【样式调整速查表 — 改这里统一全局】
// ============================================================
// ┌─────────────────────────┬───────────┬─────────────────────────────┐
// │         项              │  默认值   │         说明               │
// ├─────────────────────────┼───────────┼─────────────────────────────┤
// │ 卡片底色                │ #FFFFFF   │ 白底                        │
// │ 卡片圆角                │ 14 vp     │ 越大越圆                    │
// │ 卡片内边距(padding)     │ 12 vp     │ 内容到白边的留白            │
// │ 卡片左右外边距(margin)  │ 20 vp     │ 白色本体到屏幕左右边距      │
// │ 卡片下边距(margin)      │ 10 vp     │ 卡片之间的行间距            │
// ├─────────────────────────┼───────────┼─────────────────────────────┤
// │ 图标区域尺寸            │ 36×36 vp  │ 正方形边长                  │
// │ 图标 emoji 字大小       │ 18 vp     │                            │
// │ 图标背景圆角            │ 10 vp     │                            │
// │ 名称字大小              │ 15 vp     │ 粗体                        │
// │ 标签字大小              │ 12 vp     │                            │
// │ 标签内边距              │ 7LR/3TB   │ 紧凑型标签                  │
// │ 标签底色                │ #F5F5F5   │                            │
// │ 标签→箭头颜色           │ #CCCCCC   │                            │
// ├─────────────────────────┼───────────┼─────────────────────────────┤
// │ AutoCard 圆角           │ 16 vp     │                            │
// │ AutoCard 内边距(padding)│ 16/14 vp  │ 左右/上下                   │
// │ AutoCard 左右外边距     │ 20 vp     │ 与场景卡片一致              │
// │ AutoCard 图标尺寸       │ 44×44 vp  │                            │
// └─────────────────────────┴───────────┴─────────────────────────────┘
//
// 【阴影参数】
// ┌───────────────────┬──────────┬──────────┬─────────────────────────┐
// │      项           │ 正常抬起 │ 按下触摸 │  说明                   │
// ├───────────────────┼──────────┼──────────┼─────────────────────────┤
// │ SHADOW_RADIUS     │    8     │   16     │  扩散范围，越大越模糊   │
// │ SHADOW_OPACITY_HEX│ #0A(4%)  │ #26(15%) │  不透明度，越大越深     │
// │ SHADOW_OFFSET_Y   │    2     │    4     │  向下偏移 vp            │
// └───────────────────┴──────────┴──────────┴─────────────────────────┘
//
// 【调整建议】
// - 卡片更小：减小 padding(8)、图标尺寸(28)、标签字大小(11)
// - 卡片更大：增大 padding(16)、图标尺寸(44)
// ============================================================

// ============================================================
// 数据接口定义
// ============================================================
export interface SceneItem {
  id: string
  name: string
  desc: string
  icon: string
  color: string        // 图标背景色（Hex，如 '#FF6B35'）
  tags: string[]       // 操作列表（如 ['客厅灯→开', '空调→26℃']）
}

export interface AutoItem {
  id: string
  name: string
  desc: string
  icon: string
  color: string
  enabled: boolean
  statusText: string   // 运行中 / 已关闭
}

// ============================================================
// 【场景卡片】SceneCard  — 迷你紧凑版
// 以"回家模式"为例：
//   ┌──────────────────────────────────┐
//   │ 🏠  回家模式                      │
//   │ 客厅灯→开 → 空调→26℃ → 净化器→开│
//   └──────────────────────────────────┘
//
// 卡片高度构成（自上而下）：
//   padding top(5) + icon row(22) + tag gap(4) + tag row(~16) + padding bottom(5)
//   ≈ 52vp（旧版 ≈ 88vp，缩小约 41%）
// ============================================================
@Component
export struct SceneCard {
  @Prop scene: SceneItem
  @State private isPressed: boolean = false    // 触摸按下状态（用于动态阴影）
  onCardClick?: () => void

  build() {
    Column() {
      // =====================================================
      // 第一行：图标 + 模式名称（横向排列）
      // =====================================================
      Row() {
        // ---- 彩色图标（带圆角背景的 emoji） ----
        //   尺寸：22×22 vp（缩小以降低卡片整体高度）
        Text(this.scene.icon)
          .fontSize(14)                    // ← 图标 emoji 字大小（旧 16→14）
          .width(22)                       // ← 图标区域宽度（正方形，旧 30→22）
          .height(22)                      // ← 图标区域高度
          .textAlign(TextAlign.Center)     //    emoji 居中
          .backgroundColor(this.scene.color)   // 彩色背景（数据传入）
          .borderRadius(6)                 // ← 图标背景圆角（旧 8→6）

        // ---- 模式名称（粗体） ----
        Text(this.scene.name)
          .fontSize(13)                    // ← 名称字体大小（旧 14→13）
          .fontWeight(FontWeight.Bold)     //    粗体
          .fontColor('#1A1A1A')            //    深灰色
          .margin({ left: 6 })             // ← 图标与名称的间距（旧 8→6）

        Blank()                            //    将名称推到左侧
      }
      .width('100%')                       //    撑满整行
      .alignItems(VerticalAlign.Center)    //    垂直居中

      // =====================================================
      // 第二行：操作顺序标签
      // 每个标签 = "设备→操作" 如 "客厅灯→开"
      // 标签之间用 → 箭头连接，体现执行顺序
      // =====================================================
      Row() {
        ForEach(this.scene.tags, (tag: string, index?: number) => {
          // ---- 标签 pill ----
          Text(tag)
            .fontSize(11)                  // ← 标签文字大小（旧 12→11）
            .fontColor('#555555')          //    文字色（灰偏深）
            .backgroundColor('#F5F5F5')    // ← 标签底色（浅灰）
            .borderRadius(5)               // ← 标签圆角（旧 6→5）
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })   // ← 标签内边距（旧 6/2→5/2）

          // ---- 标签之间的顺序箭头（最后一个标签后不加箭头） ----
          if (index !== undefined && index < this.scene.tags.length - 1) {
            Text('→')
              .fontSize(9)                 // ← 箭头字大小（旧 10→9）
              .fontColor('#CCCCCC')        // ← 箭头颜色（浅灰，弱化视觉）
              .margin({ left: 2, right: 2 })  // ← 箭头与标签的间距
          }
        })
      }
      .width('100%')                       //    撑满整行
      .margin({ top: 4 })                  // ← 第二行与第一行之间的间距（旧 6→4）

      // ========================================================
      // 卡片容器样式（全部可调参数集中在此，方便全局统一修改）
      // ========================================================
      //
      // 布局示意（360vp 宽屏幕）：
      //  ┌──── 32 margin ────┬─── 296vp 白色本体 ───┬─── 32 margin ────┐
      //  │                   │ ┌╌╌ 0.5vp dashed ╌╌┐ │                  │
      //  │                   │ ╎ ┌─ 5 padding ──┐ ╎ │                  │
      //  │                   │ ╎ │ 🏠  回家模式       │ ╎ │                  │
      //  │                   │ ╎ │ 客厅灯→开→空调→..  │ ╎ │                  │
      //  │                   │ ╎ └────────────────────┘ ╎ │                  │
      //  │                   │ └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘ │                  │
      //  │                   │ ←--- bottom:10 ---→ 下一张卡片             │
      //  └───────────────────┴────────────────────────┴──────────────────┘
      //
      //  【卡片高度计算】（padding 5 + icon 22 + tag gap 4 + tag row ~16 + padding 5）
      //   ≈ 52vp（旧版 88vp，缩小 ≈ 41%）
      //
      //  【关键参数】（改这里统一调整所有场景卡片尺寸）
      //  ① padding        → 卡片内边距，vp（当前 5，越大卡片越高）
      //  ② icon width/ht  → 图标尺寸，vp（当前 22，越大第一行越高）
      //  ③ tag gap        → 标签行与图标行间距，vp（当前 4）
      //  ④ tag padding    → 标签 pill 内边距（当前 5/2）
      //
      //  ⑤ margin LR      → 卡片左右缩进，vp（当前 32，越大卡片越窄）
      //  ⑥ margin bottom  → 卡片之间的行间距（固定 10）
      // ========================================================
    }
    .width('100%')                         //    撑满父容器宽度
    .backgroundColor('#FFFFFF')            // ← 卡片底色（白底）
    // 虚线边框 — 标识卡片白色本体的边界
    //   borderWidth  → 虚线粗细（默认 0.5vp，调大则边框更粗更醒目）
    //   borderColor  → 边框颜色
    //   borderStyle  → BorderStyle.Dashed（虚线）| Solid（实线）
    //   如需隐藏边框，注释掉下方三行即可
    .borderWidth(0.5)                      // ← 边框宽度 0.5vp（虚线粗细，值越大边框越粗）
    .borderColor('#007DFF')                // ← 边框颜色（蓝色，与背景 #F2F2F7 形成对比）
    .borderStyle(BorderStyle.Dashed)       // ← 边框样式为虚线（BorderStyle.Dashed）
    .borderRadius(14)                      // ← 卡片整体圆角（虚线边框随圆角弯曲）
    .padding(5)                            // ← 卡片内边距（旧 8→5，缩小 37%，卡片更扁更紧凑）
    .margin({ left: 32, right: 32, bottom: 10 })
    //   ↑ 【白色本体左右宽度缩小】left=32, right=32（旧 20→32）
    //     白色本体宽度 = 屏幕宽度 - 64vp（旧 40vp，缩窄 24vp）
    //     注释：旧值与"场景"区标题 padding left=20 对齐；
    //     现在缩窄后卡片更小巧，左右留白更多

    // ---- 阴影：触摸按下时加深扩散（模拟按钮按下的立体感） ----
    .shadow({
      radius: this.isPressed ? 16 : 8,          // ← 阴影扩散半径（按下 16 / 正常 8）
      color: this.isPressed ? '#00000026' : '#0000000A', // ← 阴影透明度
      offsetX: 0,                                //    水平不偏移
      offsetY: this.isPressed ? 4 : 2            // ← 阴影向下偏移（按下 4 / 正常 2）
    })

    // ---- 触摸事件：监听按下/抬起切换阴影效果 ----
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })

    // ---- 点击回调：执行场景（预留 MQTT 发布入口） ----
    .onClick(() => { this.onCardClick?.() })
  }
}

// ============================================================
// 【场景模式卡片】SceneModeCard
// 虚线圆角矩形 300vp，白色背景，带按下反馈
// 用于在场景区展示单个模式详情（回家/离家/观影等）
// 从 SmartPage 迁移至此，后续统一在 SceneCard.ets 中维护样式
// ============================================================
@Component
export struct SceneModeCard {
  icon: string = ''
  name: string = ''
  color: string = ''
  tags: string[] = []
  @State private isPressed: boolean = false
  onCardClick?: () => void

  build() {
    Column() {
      // 第一行：图标 + 模式名称
      Row() {
        Text(this.icon)
          .fontSize(14)
          .width(22)
          .height(22)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.color)
          .borderRadius(6)
        Text(this.name)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({ left: 6 })
        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 第二行：操作顺序标签
      Row() {
        ForEach(this.tags, (tag: string, index?: number) => {
          Text(tag)
            .fontSize(11)
            .fontColor('#555555')
            .backgroundColor('#F5F5F5')
            .borderRadius(5)
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          if (index !== undefined && index < this.tags.length - 1) {
            Text('→')
              .fontSize(9)
              .fontColor('#CCCCCC')
              .margin({ left: 2, right: 2 })
          }
        })
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width(300)
    .padding(5)
    .backgroundColor('#FFFFFF')
    .borderWidth(this.isPressed ? 1.5 : 0.5)
    .borderColor('#007DFF')
    .borderStyle(BorderStyle.Dashed)
    .borderRadius(14)
    .alignSelf(ItemAlign.Center)
    .margin({ bottom: 8 })
    .shadow({
      radius: this.isPressed ? 12 : 6,
      color: this.isPressed ? '#0000001A' : '#00000008',
      offsetX: 0,
      offsetY: this.isPressed ? 3 : 1
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
    .onClick(() => {
      this.onCardClick?.()
    })
  }
}

// ============================================================
// 【自动化卡片】AutoCard
// 离家自动关灯 / 回家自动开灯 / 早晨窗帘开启
// 布局：左侧图标 + 中部名称/描述（自适应撑满）+ 右侧状态文字 + Toggle
// ============================================================
@Component
export struct AutoCard {
  @Prop auto: AutoItem
  onToggle?: (id: string) => void

  build() {
    Row() {
      // =====================================================
      // 左：彩色图标（带圆角背景的 emoji）
      // =====================================================
      Text(this.auto.icon)
        .fontSize(20)                       // ← 图标 emoji 字大小
        .width(44)                          // ← 图标区域宽度（正方形）
        .height(44)                         // ← 图标区域高度
        .textAlign(TextAlign.Center)        //    emoji 居中
        .backgroundColor(this.auto.color)   //    图标彩色背景（数据传入）
        .borderRadius(12)                   // ← 图标背景圆角

      // =====================================================
      // 中：名称 + 描述（纵向排列，layoutWeight 自适应撑满剩余空间）
      // =====================================================
      Column() {
        Text(this.auto.name)
          .fontSize(14)                     // ← 名称字体大小
          .fontWeight(FontWeight.Bold)      //    粗体
          .fontColor('#1A1A1A')             //    深灰色

        Text(this.auto.desc)
          .fontSize(12)                     // ← 描述字体大小
          .fontColor('#888888')             //    浅灰色
          .margin({ top: 2 })               // ← 名称与描述之间的间距
          .maxLines(2)                      //    最多 2 行，防止过长撑高
      }
      .alignItems(HorizontalAlign.Start)    //    左对齐
      .layoutWeight(1)                      //    ← 占满剩余宽度（撑开右侧 Toggle）
      .margin({ left: 12, right: 12 })      // ← 图标与文字的间距 / 文字与 Toggle 的间距

      // =====================================================
      // 右：状态文字 + Toggle 开关（纵向排列，靠右对齐）
      // =====================================================
      Column() {
        Text(this.auto.statusText)
          .fontSize(11)                     // ← 状态字体大小
          .fontColor(this.auto.enabled ? '#52C41A' : '#AAAAAA')
          //       ↑ 启用=绿色 / 关闭=灰色
          .margin({ bottom: 4 })            // ← 状态文字与 Toggle 之间的间距

        Toggle({ type: ToggleType.Switch, isOn: this.auto.enabled })
          .selectedColor('#4080FF')         // ← 开关打开时的轨道颜色
          .onChange(() => {
            this.onToggle?.(this.auto.id)   //    触发外部切换逻辑
          })
      }
      .alignItems(HorizontalAlign.End)      //    靠右对齐
    }
    // ========================================================
    // 卡片容器样式
    // ========================================================
    .width('100%')                          //    撑满父容器宽度
    .backgroundColor('#FFFFFF')             // ← 自动化卡片底色（白底）
    .borderRadius(16)                       // ← 卡片整体圆角
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    //   ↑ 卡片内边距（左右 16vp / 上下 14vp）
    .margin({ left: 20, right: 20, bottom: 10 })
    //   ↑ 【白色本体与屏幕左右边距】= left 20vp + right 20vp（与场景卡片一致）
    //   ↑ 【卡片行间距】bottom = 10vp
    .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })
    //   ↑ 阴影参数（与场景卡片正常状态一致）
    .alignItems(VerticalAlign.Center)       //    Row 内纵向居中
  }
}
