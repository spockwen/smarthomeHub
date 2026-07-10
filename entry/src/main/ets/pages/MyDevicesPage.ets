import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import { Colors, FontSize, Spacing, BorderRadius, ThemeColors } from '../common/DesignConstants'
import { DeviceStore } from '../DeviceStore'

interface DeviceInfo {
  id: string
  name: string
  icon: string
  room: string
  type: string
  online: boolean
}

@Entry
@Component
struct MyDevicesPage {
  @StorageProp('isDarkMode') isDark: boolean = false
  @StorageLink('lightOn') lightOn: boolean = true
  @StorageLink('bedroomLightOn') bedroomLightOn: boolean = false
  @StorageLink('kitchenLightOn') kitchenLightOn: boolean = true
  @StorageLink('airOn') airOn: boolean = false
  @StorageLink('doorLocked') doorLocked: boolean = true
  @StorageLink('curtainOpen') curtainOpen: boolean = false
  @StorageLink('cameraOn') cameraOn: boolean = true
  @StorageLink('socketOn') socketOn: boolean = true
  @StorageLink('tvOn') tvOn: boolean = false
  @StorageLink('airPurifierOn') airPurifierOn: boolean = false
  @StorageLink('robotVacuumOn') robotVacuumOn: boolean = false
  @StorageLink('waterHeaterOn') waterHeaterOn: boolean = false
  @StorageLink('doorSensorOn') doorSensorOn: boolean = true
  @StorageLink('bedsideLampOn') bedsideLampOn: boolean = false
  @StorageLink('heaterOn') heaterOn: boolean = false
  @State selectedFilter: string = '全部'

  private filters: string[] = ['全部', '客厅', '卧室', '厨房', '书房', '卫生间']

  private allDevices: DeviceInfo[] = [
    { id: 'light1', name: '客厅灯', icon: '💡', room: '客厅', type: 'light', online: true },
    { id: 'light2', name: '卧室灯', icon: '💡', room: '卧室', type: 'light', online: true },
    { id: 'light3', name: '厨房灯', icon: '💡', room: '厨房', type: 'light', online: true },
    { id: 'bedsideLamp', name: '床头灯', icon: '🔦', room: '卧室', type: 'light', online: true },
    { id: 'air', name: '空调', icon: '❄️', room: '客厅', type: 'air', online: true },
    { id: 'heater', name: '取暖器', icon: '🔥', room: '卧室', type: 'heater', online: true },
    { id: 'door', name: '智能门锁', icon: '🔐', room: '客厅', type: 'door', online: true },
    { id: 'curtain', name: '智能窗帘', icon: '🪟', room: '客厅', type: 'curtain', online: true },
    { id: 'camera', name: '摄像头', icon: '📹', room: '客厅', type: 'camera', online: true },
    { id: 'socket', name: '智能插座', icon: '🔌', room: '书房', type: 'socket', online: true },
    { id: 'tv', name: '电视', icon: '📺', room: '客厅', type: 'tv', online: true },
    { id: 'airPurifier', name: '空气净化器', icon: '💨', room: '卧室', type: 'airPurifier', online: true },
    { id: 'robotVacuum', name: '扫地机器人', icon: '🤖', room: '客厅', type: 'robotVacuum', online: true },
    { id: 'waterHeater', name: '热水器', icon: '♨️', room: '卫生间', type: 'waterHeater', online: true },
    { id: 'doorSensor', name: '门磁传感器', icon: '📡', room: '客厅', type: 'doorSensor', online: true }
  ]

  getFilteredDevices(): DeviceInfo[] {
    if (this.selectedFilter === '全部') {
      return this.allDevices
    }
    return this.allDevices.filter(d => d.room === this.selectedFilter)
  }

  getDeviceState(id: string): boolean {
    if (id === 'light1') return this.lightOn
    if (id === 'light2') return this.bedroomLightOn
    if (id === 'light3') return this.kitchenLightOn
    if (id === 'bedsideLamp') return this.bedsideLampOn
    if (id === 'air') return this.airOn
    if (id === 'heater') return this.heaterOn
    if (id === 'door') return this.doorLocked
    if (id === 'curtain') return this.curtainOpen
    if (id === 'camera') return this.cameraOn
    if (id === 'socket') return this.socketOn
    if (id === 'tv') return this.tvOn
    if (id === 'airPurifier') return this.airPurifierOn
    if (id === 'robotVacuum') return this.robotVacuumOn
    if (id === 'waterHeater') return this.waterHeaterOn
    if (id === 'doorSensor') return this.doorSensorOn
    return false
  }

  toggleDevice(id: string): void {
    const currentState = this.getDeviceState(id)
    const newState = !currentState
    if (id === 'light1') DeviceStore.setLightOn(newState)
    else if (id === 'light2') DeviceStore.setBedroomLightOn(newState)
    else if (id === 'light3') DeviceStore.setKitchenLightOn(newState)
    else if (id === 'bedsideLamp') DeviceStore.setBedsideLampOn(newState)
    else if (id === 'air') DeviceStore.setAirOn(newState)
    else if (id === 'heater') DeviceStore.setHeaterOn(newState)
    else if (id === 'door') DeviceStore.setDoorLocked(newState)
    else if (id === 'curtain') DeviceStore.setCurtainOpen(newState)
    else if (id === 'camera') DeviceStore.setCameraOn(newState)
    else if (id === 'socket') DeviceStore.setSocketOn(newState)
    else if (id === 'tv') DeviceStore.setTvOn(newState)
    else if (id === 'airPurifier') DeviceStore.setAirPurifierOn(newState)
    else if (id === 'robotVacuum') DeviceStore.setRobotVacuumOn(newState)
    else if (id === 'waterHeater') DeviceStore.setWaterHeaterOn(newState)
    else if (id === 'doorSensor') DeviceStore.setDoorSensorOn(newState)
  }

  build() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            router.back()
          })

        Text('我的设备')
          .fontSize(FontSize.TITLE3)
          .fontWeight(600)
          .fontColor(ThemeColors.textPrimary(this.isDark))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('+ 添加')
          .fontSize(FontSize.BODY2)
          .fontColor(Colors.BRAND_PRIMARY)
          .onClick(() => {
            router.pushUrl({ url: 'pages/DeviceAddPage' })
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.LG, right: Spacing.LG })
      .backgroundColor(ThemeColors.surface(this.isDark))

      Scroll() {
        Column({ space: Spacing.LG }) {
          Row({ space: Spacing.SM }) {
            ForEach(this.filters, (filter: string) => {
              Text(filter)
                .fontSize(FontSize.CAPTION1)
                .fontColor(this.selectedFilter === filter ? '#FFFFFF' : ThemeColors.textSecondary(this.isDark))
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.selectedFilter === filter ? Colors.BRAND_PRIMARY : ThemeColors.surface(this.isDark))
                .borderRadius(16)
                .onClick(() => {
                  this.selectedFilter = filter
                })
            })
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG })

          Row() {
            Text('共' + this.getFilteredDevices().length + '台设备')
              .fontSize(FontSize.CAPTION1)
              .fontColor(ThemeColors.textTertiary(this.isDark))

            Blank()

            Text('在线 ' + this.getFilteredDevices().filter(d => d.online).length)
              .fontSize(FontSize.CAPTION1)
              .fontColor(Colors.SUCCESS)
          }
          .width('100%')
          .padding({ left: Spacing.LG, right: Spacing.LG })

          Column({ space: Spacing.SM }) {
            ForEach(this.getFilteredDevices(), (device: DeviceInfo) => {
              Row() {
                Text(device.icon)
                  .fontSize(28)
                  .margin({ right: Spacing.MD })

                Column({ space: 4 }) {
                  Text(device.name)
                    .fontSize(FontSize.BODY1)
                    .fontColor(ThemeColors.textPrimary(this.isDark))

                  Text(device.room + ' · ' + (device.online ? '在线' : '离线'))
                    .fontSize(FontSize.CAPTION1)
                    .fontColor(ThemeColors.textSecondary(this.isDark))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: this.getDeviceState(device.id) })
                  .selectedColor(Colors.BRAND_PRIMARY)
                  .width(48)
                  .height(28)
                  .onChange((isOn: boolean) => {
                    this.toggleDevice(device.id)
                  })
              }
              .width('100%')
              .padding(Spacing.LG)
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(ThemeColors.surface(this.isDark))
            })
          }
          .padding({ left: Spacing.LG, right: Spacing.LG })
        }
        .width('100%')
        .padding({ top: Spacing.MD, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bg(this.isDark))
  }
}
