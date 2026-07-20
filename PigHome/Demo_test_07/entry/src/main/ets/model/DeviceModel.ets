// ============================================================
// 统一数据模型 - DeviceModel.ets
// 所有页面的数据结构定义在此，避免各页面重复定义
// ============================================================

// ---- 设备信息（用于【家庭】页面网格卡片） ----
export interface DeviceInfo {
  id: string
  name: string
  icon: string
  room: string
  isOn: boolean
  colSpan: number
  rowSpan: number
  gridCol: number
  gridRow: number
  statusText: string
  setting: number
}

// ---- 场景信息（用于【智能】页面场景卡片） ----
export interface SceneInfo {
  id: string
  name: string
  desc: string
  icon: string
  color: string
  tags: string[]
}

// ---- 自动化信息（用于【智能】页面自动化列表） ----
export interface AutoInfo {
  id: string
  name: string
  desc: string
  icon: string
  color: string
  enabled: boolean
  statusText: string
}

// ---- 聊天消息（用于【AI助手】页面气泡列表） ----
export interface ChatMessage {
  id: string
  role: 'user' | 'ai'
  content: string
  time: string
  isStreaming?: boolean   // AI 消息是否正在流式输出中
}

// ---- 快捷指令（用于【AI助手】页面快捷指令区） ----
export interface QuickCmd {
  label: string
  cmd: string
}

// ---- 商品信息（用于【商城】页面产品网格） ----
export interface ProductInfo {
  id: string
  name: string
  icon: string
  price: number
  originalPrice: number
}

// ---- 用电分类（用于【我的】页面用电概览） ----
export interface PowerUsage {
  name: string
  percent: number
  color: string
}

// ---- 菜单项（用于【我的】页面设置菜单列表） ----
export interface MenuOption {
  id: string
  icon: string
  iconBg: string
  label: string
  danger?: boolean
}
