/**
 * 智能温控中心 - 远程温控页
 * ------------------------------------------------------------
 * 功能：
 *   - 展示空调当前状态（来源：ClimateService.getState）
 *   - 模式切换：制冷 / 制热 / 自动 / 节能 / 睡眠 / 送风
 *   - 目标温度步进调节：范围 16-30℃，±1℃/步
 *   - 风速切换：自动 / 低速 / 中速 / 高速
 *   - 电源开关（二次确认）
 *   - 展示最近 5 条温控日志（操作者 + 动作 + 前后状态）
 *   - 展示当前跨域联动规则（命中次数 + 上次触发时间，来源：GatewayService）
 *   - "刷新"按钮：手动从 Service 拉取最新数据
 *   - "清空日志"按钮：清空 ClimateLogEntry（保留历史日志 key）
 *
 * 数据层：所有读/写均通过 ClimateService / GatewayService，页面不直接操作 AppStorage。
 * 联动层：页面 aboutToAppear 时初始化 GatewayService（幂等）；状态变更由 ClimateService
 *         自动 publish GatewayEvent 到 GatewayBus，由 GatewayService.onEvent 匹配规则
 *         并派发动作（如 门锁解锁 → 空调切回 24℃）。
 *         本页面**不**订阅 GatewayBus（避免覆盖 GatewayService 单一 handler），
 *         联动效果通过 refreshAll() 拉取 GatewayService.getRules() 的
 *         fireCount / lastFiredTime 实时增长间接验证，并在 UI 顶部展示"今日联动 N 次"。
 *
 * 样式层：颜色使用已核验的 Colors.* 常量（BRAND_PRIMARY / SUCCESS / WARNING /
 *         BG_LIGHT / TEXT_PRIMARY_LIGHT 等），尺寸/间距/圆角使用 vp / fp 字面量
 *         以避免对 DesignConstants 中未核验的成员名（如 FontSize.title）产生
 *         符号解析错误。
 */
import router from '@ohos.router'
import { Colors } from '../common/DesignConstants'
import {
  ClimateMode,
  FanSpeed,
  ThermostatState,
  ClimateLogEntry,
  AdapterBrand,
  ACAdapterFactory,
  IAirConditioner
} from '../models/ClimateModel'
import { ClimateService } from '../services/ClimateService'
import { GatewayService } from '../services/GatewayService'
import { CrossDomainRule } from '../models/GatewayModel'

const TAG = 'TemperaturePage'
const DEVICE_LABEL = '客厅中央空调'
const TEMP_MIN = 16
const TEMP_MAX = 30
const TEMP_STEP = 1
const TOAST_DURATION_MS = 2200

// 模式中英文 / 显示色 / 图标占位
// ArkTS 严格模式（arkts-no-untyped-obj-literals）禁止对象字面量直接初始化 Record<>,
// 必须用显式声明的 class/interface 包装。
function modeLabel(m: ClimateMode): string {
  switch (m) {
    case 'cool': return '制冷'
    case 'heat': return '制热'
    case 'auto': return '自动'
    case 'eco': return '节能'
    case 'sleep': return '睡眠'
    case 'fan': return '送风'
    default: return String(m)
  }
}
function modeAccent(m: ClimateMode): string {
  switch (m) {
    case 'cool': return '#007DFF'
    case 'heat': return '#FF6B35'
    case 'auto': return '#34C759'
    case 'eco': return '#00875A'
    case 'sleep': return '#7C4DFF'
    case 'fan': return '#00B8D4'
    default: return '#007DFF'
  }
}
function modeGlyph(m: ClimateMode): string {
  switch (m) {
    case 'cool': return '❄'
    case 'heat': return '☀'
    case 'auto': return 'A'
    case 'eco': return '♻'
    case 'sleep': return '☾'
    case 'fan': return '≋'
    default: return ''
  }
}

// 风速中英文 / 显示色 / 图标占位
function fanLabel(s: FanSpeed): string {
  switch (s) {
    case 'auto': return '自动'
    case 'low': return '低速'
    case 'mid': return '中速'
    case 'high': return '高速'
    default: return String(s)
  }
}
function fanGlyph(s: FanSpeed): string {
  switch (s) {
    case 'auto': return 'A'
    case 'low': return '·'
    case 'mid': return '··'
    case 'high': return '···'
    default: return ''
  }
}

// 日志动作名映射
function actionLabel(action: string): string {
  switch (action) {
    case 'power': return '电源'
    case 'mode': return '模式'
    case 'fanSpeed': return '风速'
    case 'targetTemp': return '目标温度'
    case 'adapter': return '品牌协议'
    default: return action
  }
}

// 跨域规则来源图标占位
function ruleSourceGlyph(source: string): string {
  switch (source) {
    case 'lock': return '🔒'
    case 'light': return '💡'
    case 'climate': return '🌡'
    case 'time': return '⏱'
    case 'sensor': return '👤'
    default: return '⚙'
  }
}

@Entry
@Component
struct TemperaturePage {
  @State state: ThermostatState = ClimateService.getState()
  @State logs: ClimateLogEntry[] = []
  @State rules: CrossDomainRule[] = []
  @State operator: string = 'user'
  @State isBusy: boolean = false
  @State crossDomainCount: number = 0
  @State activityHint: string = '尚未触发联动'
  @State toastVisible: boolean = false
  @State toastMessage: string = ''
  @State showConfirmPower: boolean = false
  @State pendingPower: boolean = false
  @State showOperatorInput: boolean = false
  @State operatorDraft: string = ''
  private toastTimer: number = -1

  // =============== 生命周期 ===============

  aboutToAppear() {
    console.info(TAG, 'aboutToAppear')
    try {
      GatewayService.init()
    } catch (e) {
      console.warn(TAG, `GatewayService.init failed: ${JSON.stringify(e)}`)
    }
    this.refreshAll()
  }

  aboutToDisappear() {
    console.info(TAG, 'aboutToDisappear')
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer)
      this.toastTimer = -1
    }
  }

  // =============== 数据拉取 ===============

  refreshAll() {
    try {
      const s = ClimateService.getState()
      const newLogs = ClimateService.getLogs()
      const newRules = GatewayService.getRules()

      let totalFires = 0
      let lastFiredAt = 0
      for (let i = 0; i < newRules.length; i++) {
        const rule = newRules[i]
        totalFires = totalFires + rule.fireCount
        if (rule.lastFiredTime > lastFiredAt) {
          lastFiredAt = rule.lastFiredTime
        }
      }

      const prevCount = this.crossDomainCount
      this.state = s
      this.logs = newLogs
      this.rules = newRules
      this.crossDomainCount = totalFires

      if (totalFires > prevCount && prevCount !== 0) {
        const tail = lastFiredAt > 0 ? `（上次：${this.formatTime(lastFiredAt)}）` : ''
        this.activityHint = `刚刚触发联动 · 累计 ${totalFires} 次${tail}`
      } else if (totalFires > 0) {
        const tail = lastFiredAt > 0 ? `（上次：${this.formatTime(lastFiredAt)}）` : ''
        this.activityHint = `今日联动 ${totalFires} 次${tail}`
      } else {
        this.activityHint = '尚未触发联动'
      }
    } catch (e) {
      console.error(TAG, `refreshAll failed: ${JSON.stringify(e)}`)
    }
  }

  // =============== 操作处理 ===============

  onPowerTap() {
    if (this.isBusy) return
    this.pendingPower = !this.state.power
    if (this.pendingPower) {
      // 开启：走二次确认
      this.showConfirmPower = true
    } else {
      // 关闭：直接执行（节能场景，省一步）
      this.applyPower()
    }
  }

  applyPower() {
    if (this.isBusy) return
    this.isBusy = true
    try {
      const next = ClimateService.setPower(this.pendingPower, this.operator)
      this.state = next
      this.showToast(this.pendingPower ? '空调已开启' : '空调已关闭')
      this.refreshAll()
    } catch (e) {
      console.error(TAG, `setPower failed: ${JSON.stringify(e)}`)
      this.showToast('操作失败')
    } finally {
      this.isBusy = false
    }
  }

  onConfirmPower() {
    this.showConfirmPower = false
    this.applyPower()
  }

  onCancelPower() {
    this.showConfirmPower = false
    this.pendingPower = false
  }

  onSelectMode(mode: ClimateMode) {
    if (this.isBusy) return
    if (this.state.mode === mode && this.state.power) {
      this.showToast(`已是 ${modeLabel(mode)} 模式`)
      return
    }
    if (!this.getCurrentAdapter().supportedModes.includes(mode)) {
      this.showToast('当前品牌不支持此模式')
      return
    }
    this.isBusy = true
    try {
      const next = ClimateService.setMode(mode, this.operator)
      this.state = next
      this.showToast(`已切换至${modeLabel(mode)}模式`)
      this.refreshAll()
    } catch (e) {
      console.error(TAG, `setMode failed: ${JSON.stringify(e)}`)
      this.showToast('操作失败')
    } finally {
      this.isBusy = false
    }
  }

  onSelectFanSpeed(speed: FanSpeed) {
    if (this.isBusy) return
    if (!this.state.power) {
      this.showToast('请先开启空调')
      return
    }
    if (this.state.fanSpeed === speed) {
      this.showToast(`已是 ${fanLabel(speed)} 风`)
      return
    }
    if (!this.getCurrentAdapter().supportedFanSpeeds.includes(speed)) {
      this.showToast('当前品牌不支持此风速')
      return
    }
    this.isBusy = true
    try {
      const next = ClimateService.setFanSpeed(speed, this.operator)
      this.state = next
      this.showToast(`已切换至${fanLabel(speed)}风`)
      this.refreshAll()
    } catch (e) {
      console.error(TAG, `setFanSpeed failed: ${JSON.stringify(e)}`)
      this.showToast('操作失败')
    } finally {
      this.isBusy = false
    }
  }

  onTempChange(delta: number) {
    if (this.isBusy) return
    if (!this.state.power) {
      this.showToast('请先开启空调')
      return
    }
    const adapter = this.getCurrentAdapter()
    const newTemp = this.state.targetTemp + delta
    const min = adapter.getTempMin(this.state.mode)
    const max = adapter.getTempMax(this.state.mode)
    if (newTemp < min || newTemp > max) {
      this.showToast(`温度范围：${min}-${max}℃`)
      return
    }
    this.isBusy = true
    try {
      const next = ClimateService.setTargetTemp(newTemp, this.operator)
      this.state = next
      this.showToast(`目标温度：${newTemp}℃`)
      this.refreshAll()
    } catch (e) {
      console.error(TAG, `setTargetTemp failed: ${JSON.stringify(e)}`)
      this.showToast('操作失败')
    } finally {
      this.isBusy = false
    }
  }

  onClearLogs() {
    try {
      ClimateService.clearLogs()
      this.refreshAll()
      this.showToast('温控日志已清空')
    } catch (e) {
      console.error(TAG, `clearLogs failed: ${JSON.stringify(e)}`)
      this.showToast('清空失败')
    }
  }

  onRefresh() {
    this.refreshAll()
    this.showToast('已刷新')
  }

  onOpenOperatorInput() {
    this.operatorDraft = this.operator
    this.showOperatorInput = true
  }

  onConfirmOperator() {
    const trimmed = this.operatorDraft.trim()
    if (trimmed.length === 0) {
      this.showToast('操作者不能为空')
      return
    }
    this.operator = trimmed
    this.showOperatorInput = false
    this.showToast(`操作者已设为 ${trimmed}`)
  }

  onCancelOperator() {
    this.showOperatorInput = false
  }

  onBack() {
    try {
      router.back()
    } catch (e) {
      console.warn(TAG, `router.back failed: ${JSON.stringify(e)}`)
    }
  }

  getCurrentAdapter(): IAirConditioner {
    return ACAdapterFactory.getAdapter(this.state.adapter)
  }

  onSwitchAdapter(brand: AdapterBrand) {
    if (this.isBusy) return
    if (this.state.adapter === brand) {
      this.showToast('已是当前品牌')
      return
    }
    this.isBusy = true
    try {
      const next = ClimateService.switchAdapter(brand, this.operator)
      this.state = next
      this.showToast(`已切换至${this.getCurrentAdapter().brandName}协议`)
      this.refreshAll()
    } catch (e) {
      console.error(TAG, `switchAdapter failed: ${JSON.stringify(e)}`)
      this.showToast('切换失败')
    } finally {
      this.isBusy = false
    }
  }

  adapterBrandIcon(brand: AdapterBrand): string {
    if (brand === 'gree') return '🌿'
    if (brand === 'midea') return '🦋'
    if (brand === 'haier') return '🌊'
    return '📦'
  }

  // =============== 辅助函数 ===============

  formatTime(ts: number): string {
    if (!ts || ts <= 0) return '--:--:--'
    const d = new Date(ts)
    const hh = String(d.getHours()).padStart(2, '0')
    const mm = String(d.getMinutes()).padStart(2, '0')
    const ss = String(d.getSeconds()).padStart(2, '0')
    return `${hh}:${mm}:${ss}`
  }

  formatFullTime(ts: number): string {
    if (!ts || ts <= 0) return '--'
    const d = new Date(ts)
    const M = String(d.getMonth() + 1).padStart(2, '0')
    const D = String(d.getDate()).padStart(2, '0')
    const hh = String(d.getHours()).padStart(2, '0')
    const mm = String(d.getMinutes()).padStart(2, '0')
    return `${M}-${D} ${hh}:${mm}`
  }

  formatActionText(action: string, before: string | number | boolean, after: string | number | boolean): string {
    if (action === 'targetTemp') {
      return `${Number(before).toFixed(0)}℃ → ${Number(after).toFixed(0)}℃`
    }
    if (action === 'power') {
      const b = before === true || before === 'true'
      const a = after === true || after === 'true'
      return `${b ? '开' : '关'} → ${a ? '开' : '关'}`
    }
    if (action === 'mode') {
      const b = modeLabel(before as ClimateMode)
      const a = modeLabel(after as ClimateMode)
      return `${b} → ${a}`
    }
    if (action === 'fanSpeed') {
      const b = fanLabel(before as FanSpeed)
      const a = fanLabel(after as FanSpeed)
      return `${b} → ${a}`
    }
    return `${String(before)} → ${String(after)}`
  }

  getActionLabel(action: string): string {
    return actionLabel(action)
  }

  getRuleSourceGlyph(source: string): string {
    return ruleSourceGlyph(source)
  }

  showToast(msg: string) {
    this.toastMessage = msg
    this.toastVisible = true
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer)
    }
    this.toastTimer = setTimeout(() => {
      this.toastVisible = false
      this.toastTimer = -1
    }, TOAST_DURATION_MS)
  }

  // =============== 渲染 ===============

  build() {
    Stack() {
      Column() {
        this.renderNavBar()
        Scroll() {
          Column() {
            this.renderHeaderCard()
            this.renderAdapterSection()
            this.renderTempCard()
            this.renderModeSection()
            this.renderFanSection()
            this.renderGatewaySection()
            this.renderLogSection()
            Column().height('24vp')
          }
          .width('100%')
          .padding({ left: '16vp', right: '16vp', top: '8vp' })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.BG_LIGHT)

      // 操作者输入浮层（独立 stack 层）
      if (this.showOperatorInput) {
        this.renderOperatorOverlay()
      }

      // 电源确认浮层
      if (this.showConfirmPower) {
        this.renderConfirmOverlay()
      }

      // Toast 浮层
      if (this.toastVisible) {
        this.renderToast()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ---------- 顶部导航 ----------
  @Builder
  renderNavBar() {
    Row() {
      Text('‹')
        .fontSize('28fp')
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        .onClick(() => this.onBack())
      Column() {
        Text('温控中心')
          .fontSize('20fp')
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        Text(DEVICE_LABEL)
          .fontSize('12fp')
          .fontColor('#99000000')
          .margin({ top: '2vp' })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: '12vp' })

      Text('刷新')
        .fontSize('14fp')
        .fontColor(Colors.BRAND_PRIMARY)
        .padding({ left: '12vp', right: '12vp', top: '6vp', bottom: '6vp' })
        .borderRadius('999vp')
        .backgroundColor('#1A007DFF')
        .onClick(() => this.onRefresh())
    }
    .width('100%')
    .padding({ left: '16vp', right: '16vp', top: '12vp', bottom: '12vp' })
    .backgroundColor('#FFFFFFFF')
  }

  // ---------- 主控制卡片 ----------
  @Builder
  renderHeaderCard() {
    Stack() {
      // 光晕背景
      Column()
        .width('100%')
        .height('160vp')
        .linearGradient({
          angle: 135,
          colors: this.state.power
            ? [[modeAccent(this.state.mode) + '33', 0.0], [modeAccent(this.state.mode) + '11', 1.0]]
            : [['#33000000', 0.0], ['#11000000', 1.0]]
        })
        .borderRadius('20vp')

      Column() {
        Row() {
          Column() {
            Text(this.state.power ? `${this.state.targetTemp}℃` : '--')
              .fontSize('60fp')
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY_LIGHT)
              .margin({ top: '8vp' })
            Text(this.state.power ? '目标温度' : '空调已关闭')
              .fontSize('12fp')
              .fontColor('#99000000')
              .margin({ top: '4vp' })

            Row() {
              Text(`${this.state.currentTemp}℃`)
                .fontSize('14fp')
                .fontColor('#CC000000')
              Text(' · ')
                .fontSize('14fp')
                .fontColor('#66000000')
              Text(`${this.state.humidity}%RH`)
                .fontSize('14fp')
                .fontColor('#CC000000')
            }
            .margin({ top: '12vp' })

            Text(`${modeGlyph(this.state.mode)} ${this.state.power ? modeLabel(this.state.mode) : '待机'} · ${fanLabel(this.state.fanSpeed)}风 · ${this.state.room} · ${this.getCurrentAdapter().brandName}`)
              .fontSize('12fp')
              .fontColor('#99000000')
              .margin({ top: '8vp' })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          // 电源开关（大圆按钮）
          Column() {
            Text(this.state.power ? '开' : '关')
              .fontSize('28fp')
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFFFF')
          }
          .width('72vp')
          .height('72vp')
          .borderRadius('36vp')
          .backgroundColor(this.state.power ? modeAccent(this.state.mode) : '#993B3B3B')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.onPowerTap())
        }
        .width('100%')
        .padding({ left: '20vp', right: '20vp' })
      }
      .width('100%')
      .height('160vp')
    }
    .width('100%')
    .height('160vp')
    .margin({ top: '12vp' })
  }

  // ---------- 品牌适配器选择 ----------
  @Builder
  renderAdapterSection() {
    Column() {
      Row() {
        Text('设备品牌')
          .fontSize('14fp')
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        Blank()
        Text(this.getCurrentAdapter().brandName + '协议')
          .fontSize('12fp')
          .fontColor(Colors.BRAND_PRIMARY)
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', top: '12vp', bottom: '8vp' })

      Row() {
        ForEach(ACAdapterFactory.getAllAdapters(), (adapter: IAirConditioner) => {
          Column() {
            Text(this.adapterBrandIcon(adapter.brand))
              .fontSize('24fp')
            Text(adapter.brandName)
              .fontSize('12fp')
              .fontColor(this.state.adapter === adapter.brand ? '#FFFFFFFF' : '#CC000000')
              .margin({ top: '4vp' })
          }
          .layoutWeight(1)
          .height('72vp')
          .borderRadius('14vp')
          .backgroundColor(this.state.adapter === adapter.brand ? Colors.BRAND_PRIMARY : '#F5F5F7')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: '8vp' })
          .onClick(() => this.onSwitchAdapter(adapter.brand))
        }, (adapter: IAirConditioner) => adapter.brand)
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', bottom: '16vp' })
    }
    .width('100%')
    .borderRadius('16vp')
    .backgroundColor('#FFFFFFFF')
    .margin({ top: '12vp' })
  }

  // ---------- 温度步进 ----------
  @Builder
  renderTempCard() {
    Row() {
      Text('−')
        .fontSize('28fp')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.state.power ? Colors.BRAND_PRIMARY : '#99999999')
        .width('56vp')
        .height('56vp')
        .borderRadius('28vp')
        .backgroundColor(this.state.power ? '#1A007DFF' : '#11000000')
        .textAlign(TextAlign.Center)
        .onClick(() => this.onTempChange(-TEMP_STEP))
      Column() {
        Text('目标温度')
          .fontSize('12fp')
          .fontColor('#99000000')
        Text(`${this.state.targetTemp}℃`)
          .fontSize('28fp')
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          .margin({ top: '2vp' })
        Text(`范围 ${this.getCurrentAdapter().getTempMin(this.state.mode)}-${this.getCurrentAdapter().getTempMax(this.state.mode)}℃`)
          .fontSize('11fp')
          .fontColor('#66000000')
          .margin({ top: '2vp' })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Text('+')
        .fontSize('28fp')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.state.power ? Colors.BRAND_PRIMARY : '#99999999')
        .width('56vp')
        .height('56vp')
        .borderRadius('28vp')
        .backgroundColor(this.state.power ? '#1A007DFF' : '#11000000')
        .textAlign(TextAlign.Center)
        .onClick(() => this.onTempChange(TEMP_STEP))
    }
    .width('100%')
    .padding({ left: '16vp', right: '16vp', top: '16vp', bottom: '16vp' })
    .borderRadius('16vp')
    .backgroundColor('#FFFFFFFF')
    .margin({ top: '12vp' })
  }

  // ---------- 模式选择 ----------
  @Builder
  renderModeSection() {
    Column() {
      Row() {
        Text('运行模式')
          .fontSize('14fp')
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        Blank()
        Text(this.state.power ? '已启用' : '已停用')
          .fontSize('12fp')
          .fontColor(this.state.power ? Colors.SUCCESS : '#99999999')
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', top: '12vp', bottom: '8vp' })

      Grid() {
        ForEach(this.modeList(), (item: ClimateMode) => {
          GridItem() {
            Column() {
              Text(modeGlyph(item))
                .fontSize('24fp')
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isModeActive(item) ? '#FFFFFFFF' : modeAccent(item))
              Text(modeLabel(item))
                .fontSize('12fp')
                .fontColor(this.isModeActive(item) ? '#FFFFFFFF' : '#CC000000')
                .margin({ top: '4vp' })
            }
            .width('100%')
            .height('72vp')
            .borderRadius('14vp')
            .backgroundColor(this.isModeActive(item) ? modeAccent(item) : '#F5F5F7')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => this.onSelectMode(item))
          }
        }, (item: ClimateMode) => item)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap('8vp')
      .rowsGap('8vp')
      .padding({ left: '16vp', right: '16vp', bottom: '16vp' })
      .width('100%')
      .height('160vp')
    }
    .width('100%')
    .borderRadius('16vp')
    .backgroundColor('#FFFFFFFF')
    .margin({ top: '12vp' })
  }

  modeList(): ClimateMode[] {
    return this.getCurrentAdapter().supportedModes
  }

  isModeActive(m: ClimateMode): boolean {
    return this.state.power && this.state.mode === m
  }

  // ---------- 风速选择 ----------
  @Builder
  renderFanSection() {
    Column() {
      Row() {
        Text('风速')
          .fontSize('14fp')
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        Blank()
        Text(this.state.power ? `${fanLabel(this.state.fanSpeed)}风` : '已停用')
          .fontSize('12fp')
          .fontColor(this.state.power ? Colors.SUCCESS : '#99999999')
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', top: '12vp', bottom: '8vp' })

      Row() {
        ForEach(this.fanList(), (item: FanSpeed) => {
          Column() {
            Text(fanGlyph(item))
              .fontSize('18fp')
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isFanActive(item) ? '#FFFFFFFF' : '#CC000000')
            Text(fanLabel(item))
              .fontSize('12fp')
              .fontColor(this.isFanActive(item) ? '#FFFFFFFF' : '#CC000000')
              .margin({ top: '4vp' })
          }
          .layoutWeight(1)
          .height('72vp')
          .borderRadius('14vp')
          .backgroundColor(this.isFanActive(item) ? Colors.BRAND_PRIMARY : '#F5F5F7')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: this.isLastFan(item) ? '0vp' : '8vp' })
          .onClick(() => this.onSelectFanSpeed(item))
        }, (item: FanSpeed) => item)
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', bottom: '16vp' })
    }
    .width('100%')
    .borderRadius('16vp')
    .backgroundColor('#FFFFFFFF')
    .margin({ top: '12vp' })
  }

  fanList(): FanSpeed[] {
    return this.getCurrentAdapter().supportedFanSpeeds
  }

  isFanActive(f: FanSpeed): boolean {
    return this.state.power && this.state.fanSpeed === f
  }

  isLastFan(f: FanSpeed): boolean {
    return f === 'high'
  }

  // ---------- 跨域联动状态 ----------
  @Builder
  renderGatewaySection() {
    Column() {
      Row() {
        Text('跨域联动')
          .fontSize('14fp')
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        Blank()
        Text(this.activityHint)
          .fontSize('12fp')
          .fontColor(this.crossDomainCount > 0 ? Colors.BRAND_PRIMARY : '#99999999')
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', top: '12vp', bottom: '8vp' })

      if (this.rules.length === 0) {
        Row() {
          Text('尚未配置联动规则')
            .fontSize('13fp')
            .fontColor('#99999999')
        }
        .width('100%')
        .height('64vp')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      } else {
        ForEach(this.rules, (rule: CrossDomainRule) => {
          this.renderRuleRow(rule)
        }, (rule: CrossDomainRule) => rule.id)
      }

      // 操作者行
      Row() {
        Text('当前操作者：')
          .fontSize('12fp')
          .fontColor('#99000000')
        Text(this.operator)
          .fontSize('12fp')
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        Blank()
        Text('修改')
          .fontSize('12fp')
          .fontColor(Colors.BRAND_PRIMARY)
          .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
          .borderRadius('8vp')
          .backgroundColor('#1A007DFF')
          .onClick(() => this.onOpenOperatorInput())
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', top: '12vp', bottom: '16vp' })
    }
    .width('100%')
    .borderRadius('16vp')
    .backgroundColor('#FFFFFFFF')
    .margin({ top: '12vp' })
  }

  @Builder
  renderRuleRow(rule: CrossDomainRule) {
    Row() {
      Text(this.getRuleSourceGlyph(this.extractTriggerSource(rule)))
        .fontSize('20fp')
        .width('40vp')
        .height('40vp')
        .borderRadius('20vp')
        .backgroundColor(rule.enabled ? '#1A007DFF' : '#11000000')
        .textAlign(TextAlign.Center)

      Column() {
        Row() {
          Text(rule.name)
            .fontSize('14fp')
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          if (!rule.enabled) {
            Text('已停用')
              .fontSize('10fp')
              .fontColor('#99999999')
              .margin({ left: '6vp' })
              .padding({ left: '6vp', right: '6vp', top: '2vp', bottom: '2vp' })
              .borderRadius('6vp')
              .backgroundColor('#11000000')
          }
        }
        Row() {
          Text(`触发 ${rule.fireCount} 次`)
            .fontSize('12fp')
            .fontColor('#99000000')
          if (rule.lastFiredTime > 0) {
            Text(` · 上次 ${this.formatFullTime(rule.lastFiredTime)}`)
              .fontSize('12fp')
              .fontColor('#99000000')
          }
        }
        .margin({ top: '4vp' })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: '12vp' })

      Text(rule.enabled ? '●' : '○')
        .fontSize('16fp')
        .fontColor(rule.enabled ? Colors.SUCCESS : '#99999999')
    }
    .width('100%')
    .padding({ left: '16vp', right: '16vp', top: '8vp', bottom: '8vp' })
  }

  extractTriggerSource(rule: CrossDomainRule): string {
    return rule.trigger.source
  }

  // ---------- 日志 ----------
  @Builder
  renderLogSection() {
    Column() {
      Row() {
        Text('温控日志')
          .fontSize('14fp')
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        Blank()
        Text(`共 ${this.logs.length} 条`)
          .fontSize('12fp')
          .fontColor('#99000000')
          .margin({ right: '8vp' })
        Text('清空')
          .fontSize('12fp')
          .fontColor(this.logs.length > 0 ? Colors.WARNING : '#99999999')
          .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
          .borderRadius('8vp')
          .backgroundColor(this.logs.length > 0 ? '#1AFFA000' : '#11000000')
          .onClick(() => this.onClearLogs())
      }
      .width('100%')
      .padding({ left: '16vp', right: '16vp', top: '12vp', bottom: '8vp' })

      if (this.logs.length === 0) {
        Row() {
          Text('暂无日志')
            .fontSize('13fp')
            .fontColor('#99999999')
        }
        .width('100%')
        .height('64vp')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      } else {
        ForEach(this.logs, (entry: ClimateLogEntry) => {
          this.renderLogRow(entry)
        }, (entry: ClimateLogEntry) => entry.id)
      }
    }
    .width('100%')
    .borderRadius('16vp')
    .backgroundColor('#FFFFFFFF')
    .margin({ top: '12vp' })
    .padding({ bottom: '16vp' })
  }

  @Builder
  renderLogRow(entry: ClimateLogEntry) {
    Row() {
      // 左侧时间列
      Column() {
        Text(this.formatFullTime(entry.timestamp).split(' ')[0])
          .fontSize('11fp')
          .fontColor('#99000000')
        Text(this.formatTime(entry.timestamp))
          .fontSize('12fp')
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          .margin({ top: '2vp' })
      }
      .width('60vp')
      .alignItems(HorizontalAlign.Center)

      // 右侧明细
      Column() {
        Row() {
          Text(this.getActionLabel(entry.action))
            .fontSize('13fp')
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          Blank()
          Text(`by ${entry.operator}`)
            .fontSize('11fp')
            .fontColor('#99000000')
        }
        .width('100%')

        Text(this.formatActionText(entry.action, entry.before, entry.after))
          .fontSize('12fp')
          .fontColor('#CC000000')
          .margin({ top: '4vp' })

        Text(`设备 ${entry.deviceId}`)
          .fontSize('10fp')
          .fontColor('#99999999')
          .margin({ top: '4vp' })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: '12vp' })
    }
    .width('100%')
    .padding({ left: '16vp', right: '16vp', top: '6vp', bottom: '6vp' })
  }

  // ---------- Toast 浮层 ----------
  @Builder
  renderToast() {
    Row() {
      Text('✓')
        .fontSize('14fp')
        .fontColor('#FFFFFFFF')
        .margin({ right: '8vp' })
      Text(this.toastMessage)
        .fontSize('13fp')
        .fontColor('#FFFFFFFF')
    }
    .padding({ left: '16vp', right: '16vp', top: '10vp', bottom: '10vp' })
    .borderRadius('999vp')
    .backgroundColor('#CC1F1F1F')
    .constraintSize({ maxWidth: '80%' })
  }

  // ---------- 电源确认浮层 ----------
  @Builder
  renderConfirmOverlay() {
    Column() {
      Column() {
        Text('开启空调？')
          .fontSize('18fp')
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          .margin({ top: '8vp' })

        Column() {
          Text(`设备：${DEVICE_LABEL}`)
            .fontSize('13fp')
            .fontColor('#99000000')
            .width('100%')
          Text(`当前模式：${modeLabel(this.state.mode)}`)
            .fontSize('13fp')
            .fontColor('#99000000')
            .width('100%')
            .margin({ top: '4vp' })
          Text(`目标温度：${this.state.targetTemp}℃`)
            .fontSize('13fp')
            .fontColor('#99000000')
            .width('100%')
            .margin({ top: '4vp' })
          Text(`操作者：${this.operator}`)
            .fontSize('13fp')
            .fontColor('#99000000')
            .width('100%')
            .margin({ top: '4vp' })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ top: '12vp' })

        Row() {
          Text('取消')
            .fontSize('14fp')
            .fontColor('#CC000000')
            .layoutWeight(1)
            .height('40vp')
            .textAlign(TextAlign.Center)
            .borderRadius('8vp')
            .backgroundColor('#11000000')
            .onClick(() => this.onCancelPower())
          Text('确认开启')
            .fontSize('14fp')
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFFFF')
            .layoutWeight(1)
            .height('40vp')
            .textAlign(TextAlign.Center)
            .borderRadius('8vp')
            .backgroundColor(Colors.BRAND_PRIMARY)
            .margin({ left: '12vp' })
            .onClick(() => this.onConfirmPower())
        }
        .width('100%')
        .margin({ top: '20vp' })
      }
      .padding('20vp')
      .borderRadius('16vp')
      .backgroundColor('#FFFFFFFF')
      .width('80%')
      .constraintSize({ maxWidth: '400vp' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onCancelPower())
  }

  // ---------- 操作者输入浮层 ----------
  @Builder
  renderOperatorOverlay() {
    Column() {
      Column() {
        Text('切换操作者')
          .fontSize('18fp')
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)

        Text('所有温控操作的记录人')
          .fontSize('12fp')
          .fontColor('#99000000')
          .margin({ top: '4vp' })

        TextInput({ placeholder: '输入操作者名称', text: this.operatorDraft })
          .width('100%')
          .height('44vp')
          .fontSize('14fp')
          .margin({ top: '16vp' })
          .padding({ left: '12vp', right: '12vp' })
          .backgroundColor('#F5F5F7')
          .borderRadius('8vp')
          .onChange((val: string) => {
            this.operatorDraft = val
          })

        Row() {
          Text('取消')
            .fontSize('14fp')
            .fontColor('#CC000000')
            .layoutWeight(1)
            .height('40vp')
            .textAlign(TextAlign.Center)
            .borderRadius('8vp')
            .backgroundColor('#11000000')
            .onClick(() => this.onCancelOperator())
          Text('确认')
            .fontSize('14fp')
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFFFF')
            .layoutWeight(1)
            .height('40vp')
            .textAlign(TextAlign.Center)
            .borderRadius('8vp')
            .backgroundColor(Colors.BRAND_PRIMARY)
            .margin({ left: '12vp' })
            .onClick(() => this.onConfirmOperator())
        }
        .width('100%')
        .margin({ top: '20vp' })
      }
      .padding('20vp')
      .borderRadius('16vp')
      .backgroundColor('#FFFFFFFF')
      .width('80%')
      .constraintSize({ maxWidth: '400vp' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onCancelOperator())
  }
}
