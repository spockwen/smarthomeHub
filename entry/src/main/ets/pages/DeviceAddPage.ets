/**
 * 设备添加页面
 * 提供扫描附近设备、手动添加、扫码添加、连接第三方平台等功能
 * 基于 HarmonyOS Design 规范实现
 */
import { Colors, FontSize, FontWeight, Spacing, BorderRadius, ComponentSize, GlowConfig, AnimationCurves } from '../common/DesignConstants'
import { DeviceCard, DeviceModel } from '../components/DeviceCard'
import router from '@ohos.router'

// 设备分类
type DeviceCategory = 'lighting' | 'power' | 'environment' | 'clean' | 'kitchen' | 'health' | 'security' | 'entertainment'

// 分类项接口
interface CategoryItem {
  id: DeviceCategory
  name: string
  icon: string
}

// 支持设备接口
interface SupportedDevice {
  id: string
  name: string
  model: string
  icon: string
  category: DeviceCategory
}

@Entry
@Component
export struct DeviceAddPage {
  // 搜索关键词
  @State private searchKeyword: string = ''
  
  // 当前选中的分类
  @State private currentCategory: DeviceCategory = 'lighting'
  
  // 是否正在扫描
  @State private isScanning: boolean = true
  
  // 分类列表
  private readonly categories: CategoryItem[] = [
    { id: 'lighting', name: '照明设备', icon: '💡' },
    { id: 'power', name: '电源开关', icon: '🔌' },
    { id: 'environment', name: '环境电器', icon: '🌡️' },
    { id: 'clean', name: '清洁打扫', icon: '🧹' },
    { id: 'kitchen', name: '厨房电器', icon: '🍳' },
    { id: 'health', name: '运动健康', icon: '🏃' },
    { id: 'security', name: '家居安防', icon: '🔒' },
    { id: 'entertainment', name: '娱乐影音', icon: '🎮' }
  ]
  
  // 支持设备列表
  private readonly supportedDevices: SupportedDevice[] = [
    { id: 'router1', name: '中国移动路由器', model: '通用', icon: '📶', category: 'power' },
    { id: 'scale1', name: '香山体脂秤', model: 'IF1123D', icon: '⚖️', category: 'health' },
    { id: 'light1', name: '小米智能灯泡', model: 'Yeelight', icon: '💡', category: 'lighting' },
    { id: 'socket1', name: '华为智能插座', model: 'HS100', icon: '🔌', category: 'power' },
    { id: 'thermo1', name: '格力空调', model: 'KFR-35GW', icon: '❄️', category: 'environment' },
    { id: 'vacuum1', name: '石头扫地机器人', model: 'S50', icon: '🤖', category: 'clean' },
    { id: 'camera1', name: '萤石摄像头', model: 'C6CN', icon: '📹', category: 'security' },
    { id: 'tv1', name: '华为智慧屏', model: 'V65', icon: '📺', category: 'entertainment' },
    { id: 'kettle1', name: '米家电水壶', model: 'YM-K1501', icon: '♨️', category: 'kitchen' },
    { id: 'lock1', name: '鹿客智能门锁', model: 'S30', icon: '🔐', category: 'security' },
    { id: 'speaker1', name: '小爱音箱', model: 'Play', icon: '🔊', category: 'entertainment' },
    { id: 'humidifier1', name: '智米加湿器', model: 'CJJSQ01ZM', icon: '💨', category: 'environment' }
  ]
  
  // 获取过滤后的设备列表
  private getFilteredDevices(): SupportedDevice[] {
    let filtered = this.supportedDevices
    
    // 按分类过滤
    if (this.currentCategory) {
      filtered = filtered.filter(device => device.category === this.currentCategory)
    }
    
    // 按搜索关键词过滤
    if (this.searchKeyword.trim() !== '') {
      const keyword = this.searchKeyword.toLowerCase()
      filtered = filtered.filter(device => 
        device.name.toLowerCase().includes(keyword) || 
        device.model.toLowerCase().includes(keyword)
      )
    }
    
    return filtered
  }
  
  // 开始扫描
  private startScanning() {
    this.isScanning = true
    // 模拟扫描过程
    setTimeout(() => {
      this.isScanning = false
    }, 3000)
  }
  
  // 返回上一页
  private goBack() {
    console.log('返回按钮被点击');
    try {
      router.back();
    } catch (error) {
      console.error('返回失败，跳转到首页:', error);
      router.pushUrl({
        url: 'pages/Index'
      });
    }
  }
  
  // 处理扫码添加
  private handleScanQR() {
    console.info('扫码添加设备')
    // TODO: 调用扫码功能
  }
  
  // 处理连接第三方平台
  private handleConnectPlatform() {
    console.info('连接第三方平台')
    // TODO: 跳转到第三方平台连接页面
  }
  
  // 处理设备添加
  private handleAddDevice(device: SupportedDevice) {
    console.info(`添加设备: ${device.name} (${device.model})`)
    // TODO: 实现设备添加逻辑
  }
  
  build() {
    Column() {
      // 顶部栏
      this.TopBar()
      
      // 扫描状态区
      this.ScanningSection()
      
      // 快捷操作区
      this.QuickActions()
      
      // 设备分类与支持列表
      this.DeviceListSection()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BG_LIGHT)
    .onAppear(() => {
      // 页面显示时开始扫描
      this.startScanning()
    })
  }
  
  // 顶部栏
  @Builder TopBar() {
    Row({ space: Spacing.MD }) {
      // 返回按钮
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
      }
      .width(40)
      .height(40)
      .borderRadius(BorderRadius.FULL)
      .backgroundColor(Colors.SURFACE_LIGHT)
      .onClick(() => {
        this.goBack()
      })
      
      // 搜索框
      TextInput({ placeholder: '搜索设备名称', text: this.searchKeyword })
        .placeholderFont({ size: FontSize.BODY2, weight: FontWeight.REGULAR })
        .placeholderColor(Colors.TEXT_TERTIARY_LIGHT)
        .fontColor(Colors.TEXT_PRIMARY_LIGHT)
        .fontSize(FontSize.BODY2)
        .height(40)
        .layoutWeight(1)
        .padding({ left: Spacing.LG, right: Spacing.LG })
        .backgroundColor(Colors.SURFACE_LIGHT)
        .borderRadius(BorderRadius.MEDIUM)
        .onChange((value: string) => {
          this.searchKeyword = value
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 扫描状态区
  @Builder ScanningSection() {
    Column({ space: Spacing.SM }) {
      if (this.isScanning) {
        // 加载动画
        Row() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(Colors.BRAND_PRIMARY)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: Spacing.XL, bottom: Spacing.SM })
        
        Text('正在扫描附近设备…')
          .fontSize(FontSize.BODY1)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          .fontWeight(FontWeight.MEDIUM)
      } else {
        // 扫描完成状态
        Row({ space: Spacing.SM }) {
          Text('✅')
            .fontSize(24)
            .fontColor(Colors.SUCCESS)
          
          Text('扫描完成')
            .fontSize(FontSize.BODY1)
            .fontColor(Colors.SUCCESS)
            .fontWeight(FontWeight.MEDIUM)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: Spacing.XL, bottom: Spacing.SM })
      }
      
      Text('若找不到设备，可以使用手动添加或扫码识别。')
        .fontSize(FontSize.CAPTION1)
        .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        .textAlign(TextAlign.Center)
        .padding({ left: Spacing.XL, right: Spacing.XL })
    }
    .width('100%')
    .padding({ top: Spacing.LG, bottom: Spacing.LG })
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 快捷操作区
  @Builder QuickActions() {
    Row({ space: Spacing.LG }) {
      // 扫码添加按钮
      Column({ space: Spacing.SM }) {
        Row() {
          Text('📷')
            .fontSize(32)
            .fontColor(Colors.BRAND_PRIMARY)
        }
        .width(64)
        .height(64)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius(BorderRadius.LARGE)
        .backgroundColor(Colors.BRAND_PRIMARY + '10') // 6% 透明度
        
        Text('扫码添加')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
          .fontWeight(FontWeight.MEDIUM)
      }
      .layoutWeight(1)
      .onClick(() => {
        this.handleScanQR()
      })
      
      // 连接第三方平台按钮
      Column({ space: Spacing.SM }) {
        Row() {
          Text('🔗')
            .fontSize(32)
            .fontColor(Colors.TEXT_SECONDARY_LIGHT)
        }
        .width(64)
        .height(64)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius(BorderRadius.LARGE)
        .backgroundColor(Colors.TEXT_SECONDARY_LIGHT + '10') // 6% 透明度
        
        Text('连接第三方平台')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
          .fontWeight(FontWeight.MEDIUM)
          .textAlign(TextAlign.Center)
      }
      .layoutWeight(1)
      .onClick(() => {
        this.handleConnectPlatform()
      })
    }
    .width('100%')
    .padding({ left: Spacing.XL, right: Spacing.XL, top: Spacing.LG, bottom: Spacing.LG })
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 设备分类与支持列表
  @Builder DeviceListSection() {
    Row() {
      // 左侧分类栏
      this.CategorySidebar()
      
      // 右侧设备列表
      this.DeviceList()
    }
    .layoutWeight(1)
    .width('100%')
    .backgroundColor(Colors.BG_LIGHT)
  }
  
  // 左侧分类栏
  @Builder CategorySidebar() {
    Scroll() {
      Column({ space: Spacing.XS }) {
        ForEach(this.categories, (category: CategoryItem) => {
          Column({ space: 2 }) {
            Text(category.icon)
              .fontSize(20)
            
            Text(category.name)
              .fontSize(FontSize.CAPTION1)
              .fontColor(this.currentCategory === category.id ? Colors.BRAND_PRIMARY : Colors.TEXT_SECONDARY_LIGHT)
              .fontWeight(this.currentCategory === category.id ? FontWeight.MEDIUM : FontWeight.REGULAR)
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width(72)
          .padding({ top: Spacing.MD, bottom: Spacing.MD })
          .borderRadius(BorderRadius.MEDIUM)
          .backgroundColor(this.currentCategory === category.id ? Colors.BRAND_PRIMARY + '15' : Colors.SURFACE_LIGHT)
          .onClick(() => {
            this.currentCategory = category.id
          })
        })
      }
      .padding({ top: Spacing.LG, bottom: Spacing.LG })
    }
    .width(96)
    .scrollBar(BarState.Off)
    .backgroundColor(Colors.SURFACE_LIGHT)
  }
  
  // 右侧设备列表
  @Builder DeviceList() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        Text('最新支持')
          .fontSize(FontSize.TITLE2)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          .fontWeight(FontWeight.BOLD)
          .padding({ left: Spacing.LG, top: Spacing.LG, bottom: Spacing.SM })
        
        // 设备网格
        Grid() {
          ForEach(this.getFilteredDevices(), (device: SupportedDevice) => {
            GridItem() {
              this.DeviceCard(device)
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .rowsTemplate('auto')
        .columnsGap(Spacing.MD)
        .rowsGap(Spacing.MD)
        .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XXL })
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
  
  // 设备卡片
  @Builder DeviceCard(device: SupportedDevice) {
    Column({ space: Spacing.SM }) {
      // 设备图片区域
      Row() {
        Text(device.icon)
          .fontSize(32)
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .borderRadius(BorderRadius.MEDIUM)
      .backgroundColor(Colors.BG_LIGHT)
      
      // 设备信息
      Column({ space: 2 }) {
        Text(device.name)
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.TEXT_PRIMARY_LIGHT)
          .fontWeight(FontWeight.MEDIUM)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(device.model)
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.TEXT_SECONDARY_LIGHT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: Spacing.SM, right: Spacing.SM, bottom: Spacing.SM })
    }
    .width('100%')
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(Colors.SURFACE_LIGHT)
    .padding({ bottom: Spacing.SM })
    .onClick(() => {
      this.handleAddDevice(device)
    })
  }
}