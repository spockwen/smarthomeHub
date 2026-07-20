// ============================================================
// 设备卡片组件 - DeviceCard.ets        （复用入口）
// -----------------------------------------------------------
// 用途：统一定义【家庭】页所有设备卡片的外形样式
//       （边框/大小/圆角/颜色/间距），HomePage 只传数据。
// -----------------------------------------------------------
// 使用方式（7种卡片模式）：
//
//   ① 空占位（虚线矩形参考格） —— 当格子未添加设备时显示
//      DeviceCard({ isEmpty: true })
//      DeviceCard({ isEmpty: true, spanRows: 2 })   // 跨2行
//
//   ② 标准设备卡片（72×72，1×1） —— 最常用，含图标/名称/状态/开关
//      DeviceCard({
//        icon: '💡',
//        name: '客厅主灯',
//        statusText: '100%',
//        isOn: true,                 // true→蓝底白字；false→白底黑字
//        onCardClick: () => { }
//      })
//
//   ③ 竖放家具设备卡片（72×154，1×2） —— 含竖直亮度拖动条（书房灯）
//      DeviceCard({
//        isTallDevice: true,
//        icon: '💡',
//        name: '书房灯',
//        isOn: true,
//        lightLevel: 100,
//        onCardClick: () => { },
//        onBrightnessChange: (val) => { }
//      })
//
//   ④ 竖卡（72×154，1×2 / spanRows:2）—— 通用竖放设备，不含亮度条
//      DeviceCard({
//        spanRows: 2,
//        icon: '💨',
//        name: '空气净化器',
//        statusText: 'AQI 12 优',
//        isOn: true,
//        onCardClick: () => { }
//      })
//
//   ⑤ 大块（154×154，2×2）—— 通用大块设备（如空调）
//      DeviceCard({
//        spanColumns: 2, spanRows: 2,   // 2×2=154×154
//        icon: '❄️',
//        name: '空调',
//        statusText: '运行中',
//        isOn: true,
//        onCardClick: () => { }
//      })
//
//   ⑤-A 大块带温度拖动条（154×154，2×2）—— 空调含温度调节
//      DeviceCard({
//        spanColumns: 2, spanRows: 2,
//        icon: '❄️',
//        name: '空调',
//        isOn: true,
//        showTemperatureSlider: true,    // 启用温度拖动条
//        temperature: 24,               // 当前温度 16-30
//        acMode: '制冷 · 主卧',          // 显示在名称下方的模式文本
//        onCardClick: () => { },
//        onTemperatureChange: (val) => { }
//      })
//
//   ⑥ 横放家具设备卡片（154×72，2×1）—— 含水平开合拖动条（电动窗帘）
//      DeviceCard({
//        isHorizontalDevice: true,
//        spanColumns: 2, spanRows: 1,   // 必须设置 2×1 才能占满 154vp
//        icon: '🪟',
//        name: '电动窗帘',
//        isOn: true,
//        curtainLevel: 100,            // 开合度 0-100
//        onCardClick: () => { },
//        onCurtainChange: (val) => { }
//      })
//
// ============================================================
// 【统一间距参数（可调）】
// ============================================================
// 以下参数在模块内部统一，如需修改全局间距，只需改动对应数值：
//
//  ┌──────────────────────────────────────────────────────────┐
//  │  参数名            │  默认值  │  所在文件        │  说明 │
//  ├────────────────────┼─────────┼──────────────────┼───────┤
//  │  CELL_SIZE         │  72vp   │  DeviceCard      │  单格 │
//  │  GAP_UNIT          │  10vp   │  DeviceCard      │ 相邻格│
//  │  CARD_BORDER_RADIUS│  8vp    │  DeviceCard      │ 圆角  │
//  │  SCREEN_PADDING_LR │  1vp    │  HomePage        │ 左右边│
//  │  ROW_SPACING       │  10vp   │  HomePage        │ 上下间│
//  └──────────────────────────────────────────────────────────┘
//
//  ● CELL_SIZE（单格大小）= 72vp
//    卡片实际尺寸计算公式：
//      width  = CELL_SIZE × spanColumns + GAP_UNIT × (spanColumns - 1)
//      height = CELL_SIZE × spanRows    + GAP_UNIT × (spanRows - 1)
//    例：2×2 → 72×2 + 10×1 = 154vp   |   1×2 → 72×1 + 10×0 = 72×154
//
//  ● GAP_UNIT（相邻格间距, 在 Card 层之外）= 10vp
//    影响：① 外层 Row({ space: GAP_UNIT }) 控制左右卡片间距
//          ② 外层 Column({ space: GAP_UNIT }) 控制上下卡片间距
//          ③ 实际卡片尺寸 = GAP_UNIT × (跨格数 - 1)
//
//  ● SCREEN_PADDING_LR（左右屏幕边距）= 1vp
//    在 HomePage 最外层 Column 中通过 .padding({ left: 1, right: 1 }) 设置
//    再加 内容区(154+10+154=318) = 320vp，适配 360vp 屏幕宽度
//
//  ● ROW_SPACING（上下行间距）= 10vp
//    在 HomePage 外层 Column({ space: ROW_SPACING }) 中设置
//    控制设备行与行之间的垂直间距
// ============================================================

@Component
export struct DeviceCard {
  // ---------- 对外暴露属性 ----------
  @Prop isEmpty: boolean = false       // true→只显示虚线占位框
  @Prop spanRows: number = 1            // 垂直跨越格数（1/2；对非空卡片也生效）
  @Prop spanColumns: number = 1         // 水平跨越格数（1/2；对非空卡片生效）
  @Prop isTallDevice: boolean = false   // true→竖放亮度调节卡片（72×154，与 spanRows/spanColumns 无关）
  @Prop isHorizontalDevice: boolean = false  // true→横放开合卡片（154×72，电动窗帘）
  @Prop showTemperatureSlider: boolean = false // true→2×2大块卡片中间显示温度拖动条（空调）
  @Prop icon: string = ''               // 设备图标（emoji）
  @Prop name: string = ''               // 设备名称
  @Prop statusText: string = ''         // 状态文本（开启="已开启"/关闭="已关闭"）
  @Prop isOn: boolean = false           // 控制：蓝色开 / 白色关
  @Prop lightLevel: number = 100        // 亮度百分比（仅 isTallDevice 生效）
  @Prop curtainLevel: number = 100      // 开合度百分比（仅 isHorizontalDevice 生效）
  @Prop temperature: number = 24        // 温度值（仅 showTemperatureSlider 生效）
  @Prop acMode: string = ''             // 空调模式文本，如"制冷 · 主卧"（仅 showTemperatureSlider 生效）
  @Prop badgeText: string = '运行中'     // 自定义角标文本（覆盖"运行中"）
  @Prop badgeColor: string = '#7ED167'  // 自定义角标背景色（覆盖绿色）
  @Prop badgeTextOff: string = ''       // 关闭状态下的角标文本（如"已锁定"），非空时关闭也显示角标
  @Prop badgeColorOff: string = ''      // 关闭状态下的角标背景色（如红色）
  onCardClick?: () => void
  onBrightnessChange?: (value: number) => void  // 亮度拖动回调
  onCurtainChange?: (value: number) => void     // 开合拖动回调
  onTemperatureChange?: (value: number) => void // 温度拖动回调

  build() {
    if (this.isEmpty) {
      // ======== ① 空占位（虚线矩形参考格） ========
      Column()
        .width(72)
        .height(this.spanRows === 1 ? 72
          : 72 * this.spanRows + 10 * (this.spanRows - 1))
        .border({
          width: 1.5,
          color: '#C0C0C0',
          style: BorderStyle.Dashed
        })
        .borderRadius(8)

    } else if (this.isTallDevice) {
      // ======== ③ 竖放设备卡片（72×154，含竖直亮度拖动条） ========
      // 用于灯光类家具（如书房灯），通过竖直 Slider 调节亮度
      // 高度 154 = 2×72 + 10(间距)
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          // ---- 顶部行：图标（左）+ "运行中"角标（右） ----
          Row() {
            Text(this.icon)
              .fontSize(14)
            Blank()
            if (this.isOn) {
              Text(this.badgeText)
                .fontSize(8)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .backgroundColor(this.badgeColor)
                .borderRadius(6)
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .margin({ bottom: -3 })
            } else if (this.badgeTextOff) {
              Text(this.badgeTextOff)
                .fontSize(8)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .backgroundColor(this.badgeColorOff)
                .borderRadius(6)
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .margin({ bottom: -3 })
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .height(18)

          // 上方弹性空间
          Blank().layoutWeight(1)

          // ---- 中间：竖直亮度拖动条 ----
          Row() {
            Slider({
              value: this.lightLevel,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.InSet,
              direction: Axis.Vertical,
              reverse: true     // 从下往上递增（向上拖动变亮）
            })
            .trackColor(this.isOn ? 'rgba(255,255,255,0.25)' : '#D0D0D0')
            .selectedColor(this.isOn ? '#FFFFFF' : '#4080FF')
            .blockColor(this.isOn ? '#FFFFFF' : '#4080FF')
            .blockSize({ width: 12, height: 12 })
            .trackThickness(4)
            .height(50)
            .onChange((val: number) => { this.onBrightnessChange?.(val) })
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)

          // 下方弹性空间
          Blank().layoutWeight(1)

          // ---- 底部：设备名称 + 亮度百分比 ----
          Column() {
            Text(this.name)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
              .maxLines(1)
            Text(this.lightLevel + '%')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
              .maxLines(1)
          }
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .height(22)
        }
        .width(72)
        .height(154)
        .padding(8)
        .backgroundColor(this.isOn ? '#4080FF' : '#FFFFFF')
        .border({
          width: 1.5,
          color: '#C0C0C0',
          style: BorderStyle.Dashed
        })
        .borderRadius(8)
        .onClick(() => { this.onCardClick?.() })
      }
      .width(72)
      .height(154)

    } else if (this.isHorizontalDevice) {
      // ======== ⑥ 横放家具设备卡片（154×72，含水平开合拖动条） ========
      // 用于电动窗帘等横向设备，布局（上→下）：
      //
      //   ┌────────────┬───────────────────────────────────┐
      //   │            │  电动窗帘              [运行中]    │
      //   │   🪟       │  开合度：80%  ─────Slider──────   │
      //   │            │                                   │
      //   └────────────┴───────────────────────────────────┘
      //
      // 点击切换 isOn；onCurtainChange 同步开合度到 HomePage
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          Row({ space: 6 }) {
            // ---- 最左：图标（垂直居中） ----
            Text(this.icon)
              .fontSize(20)
              .lineHeight(34)

            // ---- 右侧：两行纵向布局 ----
            Column() {
              // 第 1 行：设备名称 + 运行中角标
              Row() {
                Text(this.name)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
                  .maxLines(1)
                Blank()
                if (this.isOn) {
                  Text(this.badgeText)
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .backgroundColor(this.badgeColor)
                    .borderRadius(8)
                    .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                } else if (this.badgeTextOff) {
                  Text(this.badgeTextOff)
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .backgroundColor(this.badgeColorOff)
                    .borderRadius(8)
                    .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .height(18)

              // 第 2 行：开合度标签 + 横放开合拖动条（Slider 在开合度下方）
              Row({ space: 4 }) {
                Text('开合度：' + this.curtainLevel + '%')
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
                  .maxLines(1)

                Slider({
                  value: this.curtainLevel,
                  min: 0,
                  max: 100,
                  step: 1,
                  style: SliderStyle.InSet,
                  direction: Axis.Horizontal
                })
                  .trackColor(this.isOn ? 'rgba(255,255,255,0.25)' : '#D0D0D0')
                  .selectedColor(this.isOn ? '#FFFFFF' : '#4080FF')
                  .blockColor(this.isOn ? '#FFFFFF' : '#4080FF')
                  .blockSize({ width: 14, height: 14 })
                  .trackThickness(6)
                  .layoutWeight(1)
                  .onChange((val: number) => { this.onCurtainChange?.(val) })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .layoutWeight(1)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .height(56)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width(72 * this.spanColumns + 10 * (this.spanColumns - 1))
        .height(72 * this.spanRows + 10 * (this.spanRows - 1))
        .padding(8)
        .backgroundColor(this.isOn ? '#4080FF' : '#FFFFFF')
        .border({
          width: 1.5,
          color: '#C0C0C0',
          style: BorderStyle.Dashed
        })
        .borderRadius(8)
        .onClick(() => { this.onCardClick?.() })
      }
      .width(72 * this.spanColumns + 10 * (this.spanColumns - 1))
      .height(72 * this.spanRows + 10 * (this.spanRows - 1))

    } else {
      if (this.showTemperatureSlider && this.spanColumns === 2 && this.spanRows === 2) {
        // ======== ⑤-A 大块带温度拖动条（154×154，空调） ========
        // 顶部：图标 + "运行中"角标
        // 中部：温度水平拖动条 + 温度数值
        // 底部：设备名称 + 空调模式（如"制冷 · 主卧"）
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {
            // ---- 顶行：图标（左）+ "运行中"角标（右） ----
            Row() {
              Text(this.icon)
                .fontSize(14)
              Blank()
              if (this.isOn) {
                Text(this.badgeText)
                  .fontSize(8)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .backgroundColor(this.badgeColor)
                  .borderRadius(6)
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .margin({ bottom: -3 })
              } else if (this.badgeTextOff) {
                Text(this.badgeTextOff)
                  .fontSize(8)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .backgroundColor(this.badgeColorOff)
                  .borderRadius(6)
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .margin({ bottom: -3 })
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)

            // ---- 中部弹性填充 + 温度拖动条 + 温度数值 ----
            Blank().layoutWeight(1)

            Column({ space: 4 }) {
              Slider({
                value: this.temperature,
                min: 16,
                max: 30,
                step: 1,
                style: SliderStyle.InSet,
                direction: Axis.Horizontal
              })
                .trackColor(this.isOn ? 'rgba(255,255,255,0.25)' : '#D0D0D0')
                .selectedColor(this.isOn ? '#FFFFFF' : '#4080FF')
                .blockColor(this.isOn ? '#FFFFFF' : '#4080FF')
                .blockSize({ width: 16, height: 16 })
                .trackThickness(6)
                .width(100)
                .onChange((val: number) => { this.onTemperatureChange?.(val) })

              Text(this.temperature + '°C')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
            }
            .alignItems(HorizontalAlign.Center)
            .layoutWeight(2)

            Blank().layoutWeight(1)

            // ---- 底部：设备名称 + 空调模式 ----
            Column() {
              Text(this.name)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
                .maxLines(1)
              Text(this.acMode)
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }
          .width(72 * this.spanColumns + 10 * (this.spanColumns - 1))
          .height(72 * this.spanRows + 10 * (this.spanRows - 1))
          .padding(8)
          .backgroundColor(this.isOn ? '#4080FF' : '#FFFFFF')
          .border({
            width: 1.5,
            color: '#C0C0C0',
            style: BorderStyle.Dashed
          })
          .borderRadius(8)
          .onClick(() => { this.onCardClick?.() })
        }
        .width(72 * this.spanColumns + 10 * (this.spanColumns - 1))
        .height(72 * this.spanRows + 10 * (this.spanRows - 1))

      } else {
        // ======== ②④⑤-B 通用设备卡片（尺寸由 spanColumns×spanRows 决定） ========
      // 计算卡片实际尺寸：
      //   单格=72vp，相邻格间距=10vp
      //   width  = 72 × spanColumns + 10 × (spanColumns - 1)
      //   height = 72 × spanRows    + 10 × (spanRows - 1)
      // 常见规格：
      //   1×1=72×72、1×2=72×154、2×1=154×72、2×2=154×154
      // ----------
      // isOn=true  → 蓝底(#4080FF) + 白字 + 绿色角标(badgeText)
      // isOn=false → 白底(#FFFFFF) + 黑字 + 显示 statusText
      //             若 badgeTextOff 非空，关闭时也显示自定义角标
      // ----------

      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          // ---- 顶部行：图标（左）+ 状态角标（右） ----
          Row() {
            Text(this.icon)
              .fontSize(14)
            Blank()
            if (this.isOn) {
              Text(this.badgeText)
                .fontSize(8)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .backgroundColor(this.badgeColor)
                .borderRadius(6)
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .margin({ bottom: -3 })
            } else if (this.badgeTextOff) {
              Text(this.badgeTextOff)
                .fontSize(8)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .backgroundColor(this.badgeColorOff)
                .borderRadius(6)
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .margin({ bottom: -3 })
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Blank()

          // ---- 底部：设备名称 + 状态文本 ----
          Column() {
            Text(this.name)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
              .maxLines(1)
            Text(this.statusText)
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isOn ? '#FFFFFF' : '#1A1A1A')
              .maxLines(1)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width(72 * this.spanColumns + 10 * (this.spanColumns - 1))
        .height(72 * this.spanRows + 10 * (this.spanRows - 1))
        .padding(8)
        .backgroundColor(this.isOn ? '#4080FF' : '#FFFFFF')
        .border({
          width: 1.5,
          color: '#C0C0C0',
          style: BorderStyle.Dashed
        })
        .borderRadius(8)
        .onClick(() => { this.onCardClick?.() })
      }
      .width(72 * this.spanColumns + 10 * (this.spanColumns - 1))
      .height(72 * this.spanRows + 10 * (this.spanRows - 1))
    }
  }
  }
}
