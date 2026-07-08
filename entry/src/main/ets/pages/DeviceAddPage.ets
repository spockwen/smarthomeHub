/**
 * 设备添加页面
 * 提供扫描附近设备、手动添加、扫码添加、连接第三方平台等功能
 * 基于 HarmonyOS Design 规范实现
 */
import { Colors, FontSize, FontWeight, Spacing, BorderRadius, ComponentSize, GlowConfig, AnimationCurves, ThemeColors } from '../common/DesignConstants'
import { DeviceCard, DeviceModel } from '../components/DeviceCard'
import router from '@ohos.router'

type DeviceCategory = 'lighting' | 'power' | 'environment' | 'clean' | 'kitchen' | 'health' | 'security' | 'entertainment'

interface CategoryItem {
  id: DeviceCategory
  name: string
  icon: string
}

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
  @StorageProp('isDarkMode') isDark: boolean = false
  @State private searchKeyword: string = ''
  @State private currentCategory: DeviceCategory = 'lighting'
  @State private isScanning: boolean = true
  
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
  
  private getFilteredDevices(): SupportedDevice[] {
    let filtered = this.supportedDevices
    
    if (this.currentCategory) {
      filtered = filtered.filter(device => device.category === this.currentCategory)
    }
    
    if (this.searchKeyword.trim() !== '') {
      const keyword = this.searchKeyword.toLowerCase()
      filtered = filtered.filter(device => 
        device.name.toLowerCase().includes(keyword) || 
        device.model.toLowerCase().includes(keyword)
      )
    }
    
    return filtered
  }
  
  private startScanning() {
    this.isScanning = true
    setTimeout(() => {
      this.isScanning = false
    }, 3000)
  }
  
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
  
  private handleScanQR() {
    console.info('扫码添加设备')
  }
  
  private handleConnectPlatform() {
    console.info('连接第三方平台')
  }
  
  private handleAddDevice(device: SupportedDevice) {
    console.info(`添加设备: ${device.name} (${device.model})`)
  }
  
  build() {
    Column() {
      this.TopBar()
      this.ScanningSection()
      this.QuickActions()
      this.DeviceListSection()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
    .onAppear(() => {
      this.startScanning()
    })
  }
  
  @Builder TopBar() {
    Row({ space: Spacing.MD }) {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(ThemeColors.textPrimary(this.isDark))
      }
      .width(40)
      .height(40)
      .borderRadius(BorderRadius.FULL)
      .backgroundColor(ThemeColors.surface(this.isDark))
      .onClick(() => {
        this.goBack()
      })
      
      TextInput({ placeholder: '搜索设备名称', text: this.searchKeyword })
        .placeholderFont({ size: FontSize.BODY2, weight: FontWeight.REGULAR })
        .placeholderColor(ThemeColors.textTertiary(this.isDark))
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .fontSize(FontSize.BODY2)
        .height(40)
        .layoutWeight(1)
        .padding({ left: Spacing.LG, right: Spacing.LG })
        .backgroundColor(ThemeColors.surface(this.isDark))
        .borderRadius(BorderRadius.MEDIUM)
        .onChange((value: string) => {
          this.searchKeyword = value
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder ScanningSection() {
    Column({ space: Spacing.SM }) {
      if (this.isScanning) {
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
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .fontWeight(FontWeight.MEDIUM)
      } else {
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
        .fontColor(ThemeColors.textSecondary(this.isDark))
        .textAlign(TextAlign.Center)
        .padding({ left: Spacing.XL, right: Spacing.XL })
    }
    .width('100%')
    .padding({ top: Spacing.LG, bottom: Spacing.LG })
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder QuickActions() {
    Row({ space: Spacing.LG }) {
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
        .backgroundColor(ThemeColors.selectedBg(this.isDark))
        
        Text('扫码添加')
          .fontSize(FontSize.CAPTION1)
          .fontColor(Colors.BRAND_PRIMARY)
          .fontWeight(FontWeight.MEDIUM)
      }
      .layoutWeight(1)
      .onClick(() => {
        this.handleScanQR()
      })
      
      Column({ space: Spacing.SM }) {
        Row() {
          Text('🔗')
            .fontSize(32)
            .fontColor(ThemeColors.textSecondary(this.isDark))
        }
        .width(64)
        .height(64)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius(BorderRadius.LARGE)
        .backgroundColor(ThemeColors.selectedBg(this.isDark))
        
        Text('连接第三方平台')
          .fontSize(FontSize.CAPTION1)
          .fontColor(ThemeColors.textSecondary(this.isDark))
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
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder DeviceListSection() {
    Row() {
      this.CategorySidebar()
      this.DeviceList()
    }
    .layoutWeight(1)
    .width('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
  
  @Builder CategorySidebar() {
    Scroll() {
      Column({ space: Spacing.XS }) {
        ForEach(this.categories, (category: CategoryItem) => {
          Column({ space: 2 }) {
            Text(category.icon)
              .fontSize(20)
            
            Text(category.name)
              .fontSize(FontSize.CAPTION1)
              .fontColor(this.currentCategory === category.id ? Colors.BRAND_PRIMARY : ThemeColors.textSecondary(this.isDark))
              .fontWeight(this.currentCategory === category.id ? FontWeight.MEDIUM : FontWeight.REGULAR)
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width(72)
          .padding({ top: Spacing.MD, bottom: Spacing.MD })
          .borderRadius(BorderRadius.MEDIUM)
          .backgroundColor(this.currentCategory === category.id ? ThemeColors.selectedBg(this.isDark) : ThemeColors.surface(this.isDark))
          .onClick(() => {
            this.currentCategory = category.id
          })
        })
      }
      .padding({ top: Spacing.LG, bottom: Spacing.LG })
    }
    .width(96)
    .scrollBar(BarState.Off)
    .backgroundColor(ThemeColors.surface(this.isDark))
  }
  
  @Builder DeviceList() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        Text('最新支持')
          .fontSize(FontSize.TITLE2)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .fontWeight(FontWeight.BOLD)
          .padding({ left: Spacing.LG, top: Spacing.LG, bottom: Spacing.SM })
        
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
  
  @Builder DeviceCard(device: SupportedDevice) {
    Column({ space: Spacing.SM }) {
      Row() {
        Text(device.icon)
          .fontSize(32)
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .borderRadius(BorderRadius.MEDIUM)
      .backgroundColor(ThemeColors.bg(this.isDark))
      
      Column({ space: 2 }) {
        Text(device.name)
          .fontSize(FontSize.BODY2)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .fontWeight(FontWeight.MEDIUM)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(device.model)
          .fontSize(FontSize.CAPTION1)
          .fontColor(ThemeColors.textSecondary(this.isDark))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: Spacing.SM, right: Spacing.SM, bottom: Spacing.SM })
    }
    .width('100%')
    .borderRadius(BorderRadius.LARGE)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .padding({ bottom: Spacing.SM })
    .onClick(() => {
      this.handleAddDevice(device)
    })
  }
}
