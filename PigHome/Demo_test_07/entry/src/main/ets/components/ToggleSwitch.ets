// ============================================================
// 开关组件 - ToggleSwitch.ets
// 用于【智能】页面自动化开关 / 设备详情页等
// 复用方式：
//   ToggleSwitch({ isOn, onChange })
// ============================================================

@Component
export struct ToggleSwitch {
  @Prop isOn: boolean = false
  onChange: (val: boolean) => void = () => {}

  build() {
    Toggle({ type: ToggleType.Switch, isOn: this.isOn })
      .selectedColor('#4080FF')
      .onChange((val: boolean) => {
        this.onChange(val)
      })
  }
}
