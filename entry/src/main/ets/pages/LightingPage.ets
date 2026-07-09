/**
 * 智能照明中心（LightingPage）
 *
 * 功能分区：
 *   1. 顶部状态横幅：当前时间 / 最近事件 / 已激活规则数 / 已开灯数
 *   2. 灯组卡片：客厅 / 卧室 / 厨房 三组，含整组开关与每盏灯的状态/亮度
 *   3. 人体传感器卡片：每个传感器显示状态、最近触发时间、模拟触发 / 清除按钮
 *   4. IFTTT 联动规则列表：可启用/禁用，文字摘要展示 trigger/condition/actions
 *   5. 底部 FAB：一键"模拟有人回家" / 一键"全部离开"
 *
 * 数据流：
 *   - 进入页面 → LightingService.initialize() 注入默认值
 *   - 本地 @State 缓存列表用于渲染
 *   - 任何 set 后重新读取 → setState 触发 UI 重绘
 */

import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import {
  Light,
  LightGroup,
  MotionSensor,
  IfThisRule,
  TriggerEvent,
  RuleSummary
} from '../models/LightingModel'
import { LightingService } from '../services/LightingService'
import { RuleEngine } from '../services/RuleEngine'
import { Colors, ThemeColors } from '../common/DesignConstants'

@Entry
@Component
struct LightingPage {

  @StorageProp('isDarkMode') isDark: boolean = false

  @State private groups: LightGroup[] = []
  @State private lights: Light[] = []
  @State private sensors: MotionSensor[] = []
  @State private rules: IfThisRule[] = []
  @State private lastEvent: TriggerEvent | null = null
  @State private statusTip: string = ''

  aboutToAppear(): void {
    LightingService.initialize()
    this.refresh()
  }

  onPageShow(): void {
    this.refresh()
  }

  private refresh(): void {
    this.groups = LightingService.getGroups()
    this.lights = LightingService.getLights()
    this.sensors = LightingService.getSensors()
    this.rules = LightingService.getRules()
    this.lastEvent = LightingService.getLastEvent()
  }

  private back(): void {
    router.back()
  }

  private showTip(msg: string): void {
    this.statusTip = msg
    promptAction.showToast({ message: msg, duration: 1500 })
    setTimeout(() => {
      if (this.statusTip === msg) {
        this.statusTip = ''
      }
    }, 1500)
  }

  private getLightsByGroup(groupId: string): Light[] {
    return this.lights.filter(l => l.groupId === groupId)
  }

  private isGroupAllOn(groupId: string): boolean {
    const inGroup = this.getLightsByGroup(groupId)
    return inGroup.length > 0 && inGroup.every(l => l.isOn)
  }

  private ruleSummary(rule: IfThisRule): RuleSummary {
    return RuleEngine.describe(rule, this.sensors)
  }

  private formatTime(ts: number): string {
    if (!ts) return '从未触发'
    const d = new Date(ts)
    const hh = String(d.getHours()).padStart(2, '0')
    const mm = String(d.getMinutes()).padStart(2, '0')
    const ss = String(d.getSeconds()).padStart(2, '0')
    return `${hh}:${mm}:${ss}`
  }

  private triggeredRulesCount(): number {
    return this.rules.filter(r => r.enabled).length
  }

  private onLightsOnCount(): number {
    return this.lights.filter(l => l.isOn).length
  }

  build() {
    Stack() {
      Column() {
        // ============ 顶部标题栏 ============
        this.TitleBar()

        // ============ 状态横幅 ============
        this.StatusBanner()

        // ============ 内容滚动区 ============
        Scroll() {
          Column({ space: 16 }) {

            // ----- 灯组 -----
            this.SectionHeader('💡 灯组', `${this.onLightsOnCount()}/${this.lights.length} 已开启`)
            ForEach(this.groups, (group: LightGroup) => {
              this.GroupCard(group)
            }, (group: LightGroup) => group.id)

            // ----- 人体传感器 -----
            this.SectionHeader('👣 人体传感器', `${this.sensors.filter(s => s.detected).length} 处感应中`)
            ForEach(this.sensors, (sensor: MotionSensor) => {
              this.SensorCard(sensor)
            }, (sensor: MotionSensor) => sensor.id)

            // ----- IFTTT 联动规则 -----
            this.SectionHeader('🔗 联动规则', `${this.triggeredRulesCount()} 条已启用`)
            ForEach(this.rules, (rule: IfThisRule) => {
              this.RuleCard(rule)
            }, (rule: IfThisRule) => rule.id)

            // 底部留白，避免被 FAB 遮挡
            Column().height(80)
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.bg(this.isDark))

      // ============ 底部悬浮按钮 ============
      this.FloatingActions()
    }
    .width('100%')
    .height('100%')
  }

  // ============ 组件：标题栏 ============
  @Builder
  TitleBar() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => this.back())

      Column() {
        Text('智能照明中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary(this.isDark))
        Text('人体感应 · IFTTT 联动')
          .fontSize(12)
          .fontColor(ThemeColors.textSecondary(this.isDark))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 8 })

      Text('⟳')
        .fontSize(22)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          LightingService.resetAll()
          this.refresh()
          this.showTip('已重置为默认数据')
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }

  // ============ 组件：状态横幅 ============
  @Builder
  StatusBanner() {
    Column() {
      Row() {
        this.StatBlock('已开灯', `${this.onLightsOnCount()}/${this.lights.length}`, Colors.BRAND_PRIMARY)
        this.StatBlock('感应中', `${this.sensors.filter(s => s.detected).length}/${this.sensors.length}`, Colors.BRAND_SECONDARY)
        this.StatBlock('启用规则', `${this.triggeredRulesCount()}/${this.rules.length}`, Colors.SUCCESS)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      if (this.lastEvent) {
        Text(`最近事件：${this.lastEvent.type === 'motion_detected' ? '检测到人' : '人已离开'} · ${this.formatTime(this.lastEvent.timestamp)}`)
          .fontSize(12)
          .fontColor(ThemeColors.textSecondary(this.isDark))
          .margin({ top: 10 })
          .width('100%')
      } else {
        Text('暂无事件')
          .fontSize(12)
          .fontColor(ThemeColors.textSecondary(this.isDark))
          .margin({ top: 10 })
          .width('100%')
      }

      if (this.statusTip) {
        Text(this.statusTip)
          .fontSize(12)
          .fontColor(Colors.SUCCESS)
          .margin({ top: 4 })
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .borderRadius(12)
    .margin({ top: 12, left: 16, right: 16 })
  }

  @Builder
  StatBlock(label: string, value: string, accent: string) {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)
      Text(label)
        .fontSize(11)
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  // ============ 组件：分区头 ============
  @Builder
  SectionHeader(title: string, hint: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .layoutWeight(1)
      Text(hint)
        .fontSize(12)
        .fontColor(ThemeColors.textSecondary(this.isDark))
    }
    .width('100%')
    .margin({ top: 8, bottom: 4 })
  }

  // ============ 组件：灯组卡片 ============
  @Builder
  GroupCard(group: LightGroup) {
    Column() {
      Row() {
        Column() {
          Text(group.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.textPrimary(this.isDark))
          Text(`${group.room} · ${this.getLightsByGroup(group.id).filter(l => l.isOn).length}/${this.getLightsByGroup(group.id).length} 盏亮`)
            .fontSize(12)
            .fontColor(ThemeColors.textSecondary(this.isDark))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 整组开关
        Toggle({ type: ToggleType.Switch, isOn: this.isGroupAllOn(group.id) })
          .selectedColor(Colors.BRAND_PRIMARY)
          .switchPointColor(Color.White)
          .onChange((isOn: boolean) => {
            const inGroup = this.getLightsByGroup(group.id)
            inGroup.forEach(l => LightingService.setLightOn(l.id, isOn))
            this.refresh()
            this.showTip(`${group.name} 已${isOn ? '全部开启' : '全部关闭'}`)
          })
      }
      .width('100%')

      // 灯列表
      Column({ space: 8 }) {
        ForEach(this.getLightsByGroup(group.id), (light: Light) => {
          this.LightRow(light)
        }, (light: Light) => light.id)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .borderRadius(12)
  }

  @Builder
  LightRow(light: Light) {
    Row() {
      Column() {
        Row() {
          Text(light.isOn ? '🟡' : '⚫')
            .fontSize(14)
            .fontColor(light.isOn ? Colors.WARNING : ThemeColors.textSecondary(this.isDark))
          Text(light.name)
            .fontSize(14)
            .fontColor(ThemeColors.textPrimary(this.isDark))
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Row() {
          Text('亮度')
            .fontSize(11)
            .fontColor(ThemeColors.textSecondary(this.isDark))
          Slider({
            value: light.brightness,
            min: 0,
            max: 100,
            step: 5,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .margin({ left: 8, right: 8 })
            .blockColor(Colors.BRAND_PRIMARY)
            .trackColor(ThemeColors.divider(this.isDark))
            .selectedColor(Colors.BRAND_PRIMARY)
            .onChange((value: number) => {
              LightingService.setBrightness(light.id, value)
              this.refresh()
            })
          Text(`${light.brightness}%`)
            .fontSize(11)
            .fontColor(ThemeColors.textSecondary(this.isDark))
            .width(36)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: light.isOn })
        .selectedColor(Colors.BRAND_PRIMARY)
        .switchPointColor(Color.White)
        .onChange((isOn: boolean) => {
          LightingService.setLightOn(light.id, isOn)
          this.refresh()
        })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .borderRadius(8)
    .backgroundColor(ThemeColors.bg(this.isDark))
    .padding(8)
  }

  // ============ 组件：传感器卡片 ============
  @Builder
  SensorCard(sensor: MotionSensor) {
    Column() {
      Row() {
        Text(sensor.detected ? '🟢' : '⚪')
          .fontSize(18)

        Column() {
          Text(sensor.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeColors.textPrimary(this.isDark))
          Text(`${sensor.room} · 最近触发：${this.formatTime(sensor.lastTriggerTime)}`)
            .fontSize(11)
            .fontColor(ThemeColors.textSecondary(this.isDark))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })

        Text(sensor.detected ? '感应中' : '待机')
          .fontSize(11)
          .fontColor(sensor.detected ? Colors.SUCCESS : ThemeColors.textSecondary(this.isDark))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(sensor.detected ? '#E8F5E9' : ThemeColors.divider(this.isDark))
          .borderRadius(10)
      }
      .width('100%')

      Row({ space: 8 }) {
        Button('模拟有人')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(Colors.BRAND_PRIMARY)
          .fontColor(Color.White)
          .fontSize(13)
          .onClick(() => {
            const result = LightingService.simulateMotion(sensor.id)
            this.refresh()
            if (result.firedRuleIds.length > 0) {
              this.showTip(`已联动 ${result.firedRuleIds.length} 条规则`)
            } else {
              this.showTip('已触发，但当前无匹配规则')
            }
          })

        Button('人已离开')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(ThemeColors.bg(this.isDark))
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .fontSize(13)
          .border({ width: 1, color: ThemeColors.divider(this.isDark) })
          .onClick(() => {
            const result = LightingService.clearMotion(sensor.id)
            this.refresh()
            if (result.firedRuleIds.length > 0) {
              this.showTip(`已联动 ${result.firedRuleIds.length} 条规则`)
            } else {
              this.showTip('已清除')
            }
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .borderRadius(12)
  }

  // ============ 组件：规则卡片 ============
  @Builder
  RuleCard(rule: IfThisRule) {
    Column() {
      Row() {
        Column() {
          Text(rule.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeColors.textPrimary(this.isDark))
          Text(`触发次数：${rule.fireCount} · 最近：${this.formatTime(rule.lastFiredTime)}`)
            .fontSize(11)
            .fontColor(ThemeColors.textSecondary(this.isDark))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: rule.enabled })
          .selectedColor(Colors.BRAND_PRIMARY)
          .switchPointColor(Color.White)
          .onChange((enabled: boolean) => {
            LightingService.setRuleEnabled(rule.id, enabled)
            this.refresh()
          })
      }
      .width('100%')

      Column({ space: 4 }) {
        this.RuleLine('触发', this.ruleSummary(rule).triggerDesc, Colors.BRAND_PRIMARY)
        this.RuleLine('条件', this.ruleSummary(rule).conditionDesc, Colors.WARNING)
        this.RuleLine('动作', this.ruleSummary(rule).actionDesc, Colors.SUCCESS)
      }
      .width('100%')
      .margin({ top: 12 })
      .padding(10)
      .borderRadius(8)
      .backgroundColor(ThemeColors.bg(this.isDark))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .borderRadius(12)
  }

  @Builder
  RuleLine(label: string, value: string, accent: string) {
    Row() {
      Text(label)
        .fontSize(11)
        .fontColor(accent)
        .width(36)
      Text(value)
        .fontSize(12)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  // ============ 组件：底部浮动按钮 ============
  @Builder
  FloatingActions() {
    Row({ space: 12 }) {
      Button('🏠 模拟回家')
        .layoutWeight(1)
        .height(48)
        .backgroundColor(Colors.BRAND_PRIMARY)
        .fontColor(Color.White)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .borderRadius(24)
        .onClick(() => {
          const result = LightingService.simulateAllSensorsMotion()
          this.refresh()
          this.showTip(`已模拟回家，联动 ${result.firedRuleIds.length} 条规则`)
        })

      Button('🚪 全部离开')
        .layoutWeight(1)
        .height(48)
        .backgroundColor(ThemeColors.surface(this.isDark))
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .borderRadius(24)
        .border({ width: 1, color: ThemeColors.divider(this.isDark) })
        .onClick(() => {
          const result = LightingService.simulateAllSensorsClear()
          this.refresh()
          this.showTip(`已模拟离开，联动 ${result.firedRuleIds.length} 条规则`)
        })
    }
    .width('90%')
    .position({ x: '5%', y: '92%' })
  }
}