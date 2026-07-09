/**
 * 智能门锁 - 远程开锁页
 * ------------------------------------------------------------
 * 功能：
 *   - 展示门锁当前状态、电量、最近更新（来源：DoorLockService）
 *   - 远程开锁按钮（二次确认 + 模拟 1.2s 延时，来源于 Service 的 async unlock）
 *   - 一键上锁（同步，来源于 Service 的 lock）
 *   - 展示最近 5 条开锁日志（操作者 + 来源 + 结果）
 *   - 展示当前全部跨域联动规则（命中次数 + 上次触发时间，来源：GatewayService）
 *   - "刷新"按钮：手动从 Service 重新拉取数据
 *   - "清空日志"按钮：清空 UnlockLogEntry（保留历史日志 key）
 *
 * 数据层：所有读/写均通过 DoorLockService / GatewayService，页面不直接操作 AppStorage。
 * 联动层：页面 aboutToAppear 时初始化 GatewayService（幂等）；开锁后由
 *         GatewayService 内部处理联动（开灯、调温等），本页面仅负责 UI 呈现。
 */

import { Colors, FontSize, Spacing, BorderRadius } from '../common/DesignConstants'
import { DoorLockService } from '../services/DoorLockService'
import { GatewayService } from '../services/GatewayService'
import {
  DoorLockStateRecord,
  UnlockLogEntry,
  UnlockResult
} from '../models/DoorLockModel'
import { CrossDomainRule } from '../models/GatewayModel'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

interface DoorLockTheme {
  bg: string
  cardBg: string
  textPrimary: string
  textSecondary: string
  textMuted: string
  border: string
  success: string
  warning: string
  danger: string
  accent: string
}

// ==================== 页面 ====================
@Entry
@Component
struct DoorLockPage {
  @StorageProp('isDarkMode') isDark: boolean = false

  // 门锁状态（来源于 DoorLockService，每次操作后手动刷新）
  @State lockState: DoorLockStateRecord = DoorLockService.getState()

  // 开锁日志（来源于 DoorLockService）
  @State unlockLogs: UnlockLogEntry[] = []

  // 跨域联动规则（来源于 GatewayService）
  @State rules: CrossDomainRule[] = []

  // 操作者名称（写入日志的 operator 字段）
  @State operator: string = '家庭成员'

  // UI 状态
  @State isUnlocking: boolean = false
  @State showConfirm: boolean = false
  @State showClearConfirm: boolean = false

  aboutToAppear(): void {
    // 幂等初始化 GatewayService（首次启动写入 3 条预置规则 + 订阅 GatewayBus）
    try {
      GatewayService.init()
    } catch (e) {
      console.error('[DoorLockPage] GatewayService.init failed:', JSON.stringify(e))
    }
    this.refreshAll()
  }

  // ---------------- 数据刷新 ----------------
  private refreshAll(): void {
    this.lockState = DoorLockService.getState()
    this.unlockLogs = DoorLockService.getLogs()
    this.rules = GatewayService.getRules()
  }

  // ---------------- UI 事件 ----------------
  private onBackClick(): void {
    router.back()
  }

  private onUnlockClick(): void {
    if (this.isUnlocking) {
      return
    }
    if (this.lockState.state !== 'locked') {
      promptAction.showToast({ message: '门锁当前未处于锁定状态', duration: 1500 })
      return
    }
    this.showConfirm = true
  }

  private onCancelUnlock(): void {
    this.showConfirm = false
  }

  private async onConfirmUnlock(): Promise<void> {
    this.showConfirm = false
    if (this.isUnlocking) {
      return
    }
    this.isUnlocking = true
    try {
      // Service 内部完成：写"开始"日志 → 延时 1.2s → 切状态 → 写"成功"日志 → 发布 lock.unlocked 事件
      // GatewayService 监听到事件后自动触发联动（客厅灯开 + 空调 24°C 等），无需本页面干预
      const next: DoorLockStateRecord = await DoorLockService.unlock(this.operator, 'remote')
      this.lockState = next
      this.unlockLogs = DoorLockService.getLogs()
      this.rules = GatewayService.getRules()
      promptAction.showToast({ message: '开锁成功，联动已触发', duration: 2000 })
    } catch (e) {
      console.error('[DoorLockPage] unlock failed:', JSON.stringify(e))
      promptAction.showToast({ message: '开锁失败，请稍后重试', duration: 2000 })
    } finally {
      this.isUnlocking = false
    }
  }

  private onLockClick(): void {
    if (this.isUnlocking) {
      return
    }
    if (this.lockState.state === 'locked') {
      promptAction.showToast({ message: '门锁当前已是锁定状态', duration: 1500 })
      return
    }
    // Service 内部完成：切状态 → 写"成功"日志 → 发布 lock.locked 事件
    const next: DoorLockStateRecord = DoorLockService.lock(this.operator, 'manual')
    this.lockState = next
    this.unlockLogs = DoorLockService.getLogs()
    this.rules = GatewayService.getRules()
    promptAction.showToast({ message: '门锁已上锁', duration: 1500 })
  }

  private onClearLogsClick(): void {
    this.showClearConfirm = true
  }

  private onConfirmClearLogs(): void {
    this.showClearConfirm = false
    DoorLockService.clearLogs()
    this.unlockLogs = []
    promptAction.showToast({ message: '开锁日志已清空', duration: 1500 })
  }

  private onCancelClearLogs(): void {
    this.showClearConfirm = false
  }

  // ---------------- 格式化 ----------------
  private formatTime(ts: number): string {
    if (!ts || ts <= 0) {
      return '尚未触发'
    }
    const d: Date = new Date(ts)
    const pad: (n: number) => string = (n) => (n < 10 ? '0' + n : '' + n)
    return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
  }

  private formatDateTime(ts: number): string {
    if (!ts || ts <= 0) {
      return '-'
    }
    const d: Date = new Date(ts)
    const pad: (n: number) => string = (n) => (n < 10 ? '0' + n : '' + n)
    const m: string = pad(d.getMonth() + 1)
    const day: string = pad(d.getDate())
    return `${m}-${day} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
  }

  private resultLabel(r: UnlockResult): string {
    switch (r) {
      case 'success':
        return '成功'
      case 'failed':
        return '失败'
      case 'cancelled':
        return '已取消'
      default:
        return String(r)
    }
  }

  private resultColor(r: UnlockResult, theme: DoorLockTheme): string {
    switch (r) {
      case 'success':
        return theme.success
      case 'failed':
        return theme.danger
      case 'cancelled':
        return theme.textMuted
      default:
        return theme.textPrimary
    }
  }

  private sourceLabel(s: string): string {
    switch (s) {
      case 'remote':
        return '远程'
      case 'manual':
        return '手动'
      case 'rule':
        return '联动'
      default:
        return s
    }
  }

  // 过滤掉 Service 内部的"开始"占位日志（其 result='cancelled'，且 id 以 unlock-start 结尾）
  private displayLogs(): UnlockLogEntry[] {
    return this.unlockLogs
      .filter(l => l.result !== 'cancelled')
      .slice(0, 5)
  }

  // 主题色（响应 isDark）
  private palette(): DoorLockTheme {
    return this.isDark ? {
      bg: '#1a1a1a',
      cardBg: '#2a2a2a',
      textPrimary: '#ffffff',
      textSecondary: '#cccccc',
      textMuted: '#888888',
      border: '#3a3a3a',
      success: '#4ade80',
      warning: '#fbbf24',
      danger: '#f87171',
      accent: '#60a5fa'
    } as DoorLockTheme : {
      bg: '#f5f5f7',
      cardBg: '#ffffff',
      textPrimary: '#1a1a1a',
      textSecondary: '#444444',
      textMuted: '#888888',
      border: '#e5e5e7',
      success: '#10b981',
      warning: '#f59e0b',
      danger: '#ef4444',
      accent: '#3b82f6'
    } as DoorLockTheme
  }

  build() {
    Stack() {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.palette().bg)

      Column() {
        // 顶部导航
        this.TopBar(this.palette())

        // 主体内容
        Scroll() {
          Column() {
            // 状态卡
            this.StatusCard(this.palette())

            // 操作按钮区
            this.ActionArea(this.palette())

            // 跨域联动规则卡
            this.RulesCard(this.palette())

            // 开锁日志卡
            this.LogsCard(this.palette())
          }
          .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.MD, bottom: Spacing.XL })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')

      // 二次确认弹窗（远程开锁）
      if (this.showConfirm) {
        this.ConfirmDialog(this.palette())
      }

      // 清空日志确认弹窗
      if (this.showClearConfirm) {
        this.ClearLogsDialog(this.palette())
      }
    }
    .width('100%')
    .height('100%')
  }

  // ---------------- 子组件：顶部导航 ----------------
  @Builder
  TopBar(theme: DoorLockTheme) {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(theme.textPrimary)
        .padding(Spacing.SM)
        .onClick(() => this.onBackClick())
      Text('门锁中心')
        .fontSize(FontSize.TITLE1)
        .fontWeight(FontWeight.Medium)
        .fontColor(theme.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('刷新')
        .fontSize(FontSize.BODY1)
        .fontColor(theme.accent)
        .padding(Spacing.SM)
        .onClick(() => {
          this.refreshAll()
          promptAction.showToast({ message: '已刷新', duration: 800 })
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(theme.cardBg)
  }

  // ---------------- 子组件：门锁状态卡 ----------------
  @Builder
  StatusCard(theme: DoorLockTheme) {
    Column() {
      Text(this.lockState.state === 'unlocked' ? '🔓' : (this.lockState.state === 'jammed' ? '⚠' : '🔒'))
        .fontSize(72)
        .margin({ top: Spacing.MD, bottom: Spacing.SM })

      Text(this.lockState.state === 'unlocked' ? '已开锁' : (this.lockState.state === 'jammed' ? '锁体异常' : '已上锁'))
        .fontSize(FontSize.TITLE1)
        .fontWeight(FontWeight.Bold)
        .fontColor(
          this.lockState.state === 'unlocked' ? theme.warning :
            (this.lockState.state === 'jammed' ? theme.danger : theme.success)
        )
        .margin({ bottom: Spacing.XS })

      Text(this.lockState.name)
        .fontSize(FontSize.BODY1)
        .fontColor(theme.textSecondary)
        .margin({ bottom: Spacing.XS })

      Row() {
        Text(`电量 ${this.lockState.battery}%`)
          .fontSize(FontSize.CAPTION1)
          .fontColor(theme.textMuted)
        Text(' · ')
          .fontSize(FontSize.CAPTION1)
          .fontColor(theme.textMuted)
        Text(this.formatDateTime(this.lockState.updatedAt))
          .fontSize(FontSize.CAPTION1)
          .fontColor(theme.textMuted)
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(theme.cardBg)
    .borderRadius(BorderRadius.LARGE)
    .margin({ bottom: Spacing.MD })
  }

  // ---------------- 子组件：操作按钮区 ----------------
  @Builder
  ActionArea(theme: DoorLockTheme) {
    Column() {
      if (this.isUnlocking) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(theme.accent)
          Text('正在开锁...')
            .fontSize(FontSize.BODY1)
            .fontColor(theme.textSecondary)
            .margin({ top: Spacing.SM })
        }
        .padding(Spacing.LG)
      } else if (this.lockState.state === 'locked') {
        Button('远程开锁')
          .width('100%')
          .height(52)
          .fontSize(FontSize.TITLE3)
          .fontColor(Color.White)
          .backgroundColor(theme.accent)
          .borderRadius(BorderRadius.MEDIUM)
          .onClick(() => this.onUnlockClick())
      } else {
        Button('一键上锁')
          .width('100%')
          .height(52)
          .fontSize(FontSize.TITLE3)
          .fontColor(Color.White)
          .backgroundColor(theme.success)
          .borderRadius(BorderRadius.MEDIUM)
          .onClick(() => this.onLockClick())
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(theme.cardBg)
    .borderRadius(BorderRadius.LARGE)
    .margin({ bottom: Spacing.MD })
  }

  // ---------------- 子组件：跨域联动规则卡 ----------------
  @Builder
  RulesCard(theme: DoorLockTheme) {
    Column() {
      Row() {
        Text(`联动规则 (${this.rules.length})`)
          .fontSize(FontSize.TITLE3)
          .fontWeight(FontWeight.Medium)
          .fontColor(theme.textPrimary)
        Blank()
        Text('由 GatewayService 编排')
          .fontSize(FontSize.CAPTION2)
          .fontColor(theme.textMuted)
      }
      .width('100%')
      .margin({ bottom: Spacing.SM })

      if (this.rules.length === 0) {
        Text('暂未配置联动规则')
          .fontSize(FontSize.BODY1)
          .fontColor(theme.textMuted)
          .padding(Spacing.MD)
      } else {
        ForEach(this.rules, (r: CrossDomainRule) => {
          Row() {
            Column() {
              Row() {
                Text(r.name)
                  .fontSize(FontSize.BODY1)
                  .fontColor(theme.textPrimary)
                  .fontWeight(FontWeight.Medium)
                Text(r.enabled ? ' · 启用' : ' · 停用')
                  .fontSize(FontSize.CAPTION1)
                  .fontColor(r.enabled ? theme.success : theme.textMuted)
              }
              Text(this.describeRule(r))
                .fontSize(FontSize.CAPTION2)
                .fontColor(theme.textSecondary)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column() {
              Text(`触发 ${r.fireCount} 次`)
                .fontSize(FontSize.CAPTION1)
                .fontColor(theme.accent)
                .textAlign(TextAlign.End)
              Text(this.formatTime(r.lastFiredTime))
                .fontSize(FontSize.CAPTION2)
                .fontColor(theme.textMuted)
                .textAlign(TextAlign.End)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ top: Spacing.SM, bottom: Spacing.SM })
          .border({ width: { top: 1 }, color: { top: theme.border } })
        }, (r: CrossDomainRule) => r.id)
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(theme.cardBg)
    .borderRadius(BorderRadius.LARGE)
    .margin({ bottom: Spacing.MD })
  }

  // 简单描述一条联动规则（无需依赖 RuleEngine.describeCrossDomain 以避免循环引用）
  private describeRule(r: CrossDomainRule): string {
    const triggerText: string = r.trigger.window
      ? `${r.trigger.source}·${r.trigger.type}（${r.trigger.window}）`
      : `${r.trigger.source}·${r.trigger.type}`
    const acts: string = r.actions.map(a => {
      const target: string = a.targets[0] ?? ''
      return `${a.domain}·${a.op}(${target})`
    }).join(' + ')
    return `当 ${triggerText} → ${acts}`
  }

  // ---------------- 子组件：开锁日志卡 ----------------
  @Builder
  LogsCard(theme: DoorLockTheme) {
    Column() {
      Row() {
        Text('开锁日志')
          .fontSize(FontSize.TITLE3)
          .fontWeight(FontWeight.Medium)
          .fontColor(theme.textPrimary)
        Blank()
        Text('清空')
          .fontSize(FontSize.CAPTION1)
          .fontColor(theme.danger)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: 4, bottom: 4 })
          .onClick(() => this.onClearLogsClick())
      }
      .width('100%')
      .margin({ bottom: Spacing.SM })

      if (this.displayLogs().length === 0) {
        Text('暂无开锁日志')
          .fontSize(FontSize.BODY1)
          .fontColor(theme.textMuted)
          .padding(Spacing.MD)
      } else {
        ForEach(this.displayLogs(), (log: UnlockLogEntry) => {
          Row() {
            Text(this.formatDateTime(log.timestamp))
              .fontSize(FontSize.CAPTION1)
              .fontColor(theme.textMuted)
              .width(110)
            Text(log.operator)
              .fontSize(FontSize.BODY1)
              .fontColor(theme.textPrimary)
              .layoutWeight(1)
            Text(`[${this.sourceLabel(log.source)}]`)
              .fontSize(FontSize.CAPTION2)
              .fontColor(theme.textSecondary)
              .margin({ right: Spacing.XS })
            Text(this.resultLabel(log.result))
              .fontSize(FontSize.CAPTION1)
              .fontColor(this.resultColor(log.result, theme))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding({ top: Spacing.XS, bottom: Spacing.XS })
        }, (log: UnlockLogEntry) => log.id)
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(theme.cardBg)
    .borderRadius(BorderRadius.LARGE)
  }

  // ---------------- 子组件：二次确认弹窗 ----------------
  @Builder
  ConfirmDialog(theme: DoorLockTheme) {
    Column() {
      Column() {
        Text('远程开锁确认')
          .fontSize(FontSize.TITLE3)
          .fontWeight(FontWeight.Bold)
          .fontColor(theme.textPrimary)
          .margin({ bottom: Spacing.SM })

        Text('请确认是本人操作，开锁将自动触发联动。')
          .fontSize(FontSize.BODY1)
          .fontColor(theme.textSecondary)
          .textAlign(TextAlign.Center)
          .margin({ bottom: Spacing.LG })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(theme.bg)
            .fontColor(theme.textPrimary)
            .borderRadius(BorderRadius.MEDIUM)
            .onClick(() => this.onCancelUnlock())

          Button('确认开锁')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(theme.accent)
            .fontColor(Color.White)
            .borderRadius(BorderRadius.MEDIUM)
            .margin({ left: Spacing.SM })
            .onClick(() => this.onConfirmUnlock())
        }
        .width('100%')
      }
      .width('80%')
      .padding(Spacing.LG)
      .backgroundColor(theme.cardBg)
      .borderRadius(BorderRadius.LARGE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
  }

  // ---------------- 子组件：清空日志确认弹窗 ----------------
  @Builder
  ClearLogsDialog(theme: DoorLockTheme) {
    Column() {
      Column() {
        Text('清空开锁日志')
          .fontSize(FontSize.TITLE3)
          .fontWeight(FontWeight.Bold)
          .fontColor(theme.textPrimary)
          .margin({ bottom: Spacing.SM })

        Text('该操作不可撤销，确定要清空全部开锁日志吗？')
          .fontSize(FontSize.BODY1)
          .fontColor(theme.textSecondary)
          .textAlign(TextAlign.Center)
          .margin({ bottom: Spacing.LG })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(theme.bg)
            .fontColor(theme.textPrimary)
            .borderRadius(BorderRadius.MEDIUM)
            .onClick(() => this.onCancelClearLogs())

          Button('确定清空')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(theme.danger)
            .fontColor(Color.White)
            .borderRadius(BorderRadius.MEDIUM)
            .margin({ left: Spacing.SM })
            .onClick(() => this.onConfirmClearLogs())
        }
        .width('100%')
      }
      .width('80%')
      .padding(Spacing.LG)
      .backgroundColor(theme.cardBg)
      .borderRadius(BorderRadius.LARGE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
  }
}
