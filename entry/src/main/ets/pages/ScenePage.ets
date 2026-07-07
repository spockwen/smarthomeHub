/**
 * 场景页面 - 全新设计
 * 顶部：手机状态栏 + 页面标题「场景」+ 右上角黑色「+」按钮
 * 上半区：白色大圆角卡片「我的场景」
 * 下半区：推荐场景竖向卡片
 * 视觉风格：柔和简约家居风
 */
import { Colors, FontSize, Spacing, BorderRadius, ComponentSize } from '../common/DesignConstants'
import router from '@ohos.router'
import { SceneStore, SceneModel } from '../SceneStore'


// 推荐场景数据模型
interface RecommendedScene {
  id: string
  title: string
  description: string
  tags: string[]           // 设备标签
  gradientColors: string[] // 渐变颜色 [start, end]
  imageName: string        // 背景图片名称（假设有对应资源）
}

@Component
export struct ScenePage {
  // 用户创建的场景 - 使用 AppStorage 自动同步
  @StorageLink('userScenes') userScenes: SceneModel[] = []
  
  // 推荐场景固定内容
  @State private recommendedScenes: RecommendedScene[] = [
    {
      id: 'leave_home',
      title: '安心离家',
      description: '定义专属的离家场景，成为节能家居小达人',
      tags: ['开关', '灯', '空调'],
      gradientColors: ['#F5E6D3', '#D4B483'], // 暖棕渐变
      imageName: 'scene_leave_home'
    },
    {
      id: 'alert',
      title: '异常警报',
      description: '感应到异常状态，立即告警和补救',
      tags: ['门磁传感器'],
      gradientColors: ['#FFD8CC', '#FF9A7A'], // 橙红渐变
      imageName: 'scene_alert'
    },
    {
      id: 'morning',
      title: '早起习惯',
      description: '养成健康生活习惯，开启元气一天',
      tags: ['灯', '空调', '空气净化器'],
      gradientColors: ['#FFF9E6', '#FFE699'], // 浅黄渐变
      imageName: 'scene_morning'
    },
    {
      id: 'sleep',
      title: '就寝提醒',
      description: '按时早睡，营造舒适的睡眠环境',
      tags: ['灯', '插座', '开关'],
      gradientColors: ['#E8D9C5', '#B89B7D'], // 深棕渐变
      imageName: 'scene_sleep'
    },
    {
      id: 'back_home',
      title: '温馨回家',
      description: '定义专属的回家场景，享受悠闲的家庭时光',
      tags: ['空气净化器', '扫地机器人', '灯'],
      gradientColors: ['#F0F0F0', '#D9D9D9'], // 浅灰渐变
      imageName: 'scene_back_home'
    }
  ]

  aboutToAppear(): void {
    // 初始化场景存储
    SceneStore.initialize()
  }

  build() {
    Column() {
      // 顶部状态栏区域（占位）
      this.StatusBarPlaceholder()
      
      // 页面标题栏
      this.TitleBar()
      
      Scroll() {
        Column({ space: Spacing.XL }) {
          // 上半区：我的场景卡片
          this.MySceneCard()
          
          // 下半区：推荐场景
          this.RecommendedScenesSection()
        }
        .width('100%')
        .padding({ left: Spacing.LG, right: Spacing.LG, bottom: Spacing.XXL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA') // 极浅灰白色背景
  }

  // 状态栏占位（实际项目中应使用系统状态栏）
  @Builder StatusBarPlaceholder() {
    Row()
      .width('100%')
      .height(24) // 状态栏高度
      .linearGradient({
        angle: 180,
        colors: [
          ['#E0F7FA', 0],    // 浅青色
          ['#B2EBF2', 1]     // 稍深青色
        ]
      })
  }

  // 标题栏
  @Builder TitleBar() {
    Row() {
      // 页面标题
      Text('场景')
        .fontSize(FontSize.TITLE1)
        .fontWeight(700)
        .fontColor('#000000') // 黑色文字
        .margin({ left: Spacing.LG })
      
      Blank()
      
      // 右上角黑色「+」按钮
      Text('+')
        .fontSize(32)
        .fontWeight(300)
        .fontColor('#000000') // 黑色
        .margin({ right: Spacing.LG })
        .onClick(() => {
          console.log('点击了添加按钮，跳转到创建场景页面')
          router.pushUrl({
            url: 'pages/SceneCreatePage'
          })
        })
    }
    .width('100%')
    .height(56)
    .linearGradient({
      angle: 180,
      colors: [
        ['#E0F7FA', 0],    // 浅青色
        ['#B2EBF2', 1]     // 稍深青色
      ]
    })
    .justifyContent(FlexAlign.Center)
  }

  // 我的场景卡片
  @Builder MySceneCard() {
    Column({ space: Spacing.MD }) {
      // 卡片标题
      Text('我的场景')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor('#000000')
        .margin({ left: Spacing.LG, top: Spacing.LG })
        .alignSelf(ItemAlign.Start)
      
      // 用户创建的场景列表
      Column({ space: 0 }) {
        ForEach(this.userScenes, (scene: SceneModel, index: number) => {
          // 场景条目
          Row() {
            // 左侧图标（使用场景颜色）
            Row()
              .width(40)
              .height(40)
              .borderRadius(BorderRadius.MEDIUM)
              .backgroundColor(scene.color)
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .margin({ left: Spacing.LG })
              .shadow({
                radius: 4,
                color: scene.color + '33', // 20% 透明度
                offsetX: 0,
                offsetY: 2
              }) {
              Text(scene.icon)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .fontWeight(700)
            }
            
            // 文字区域
            Column({ space: 4 }) {
              Text(scene.name)
                .fontSize(FontSize.BODY1)
                .fontWeight(500)
                .fontColor('#000000')
              
              Text(scene.description || '暂无描述')
                .fontSize(FontSize.CAPTION1)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .margin({ left: Spacing.MD })
            .layoutWeight(1)
            
            // 右侧箭头
            Text('›')
              .fontSize(24)
              .fontColor('#999999')
              .margin({ right: Spacing.LG })
          }
          .width('100%')
          .height(60)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            console.log('点击场景:', scene.name)
            // 跳转到场景详情页
            router.pushUrl({
              url: 'pages/SceneDetailPage',
              params: { sceneId: scene.id }
            })
          })
          
          // 分隔线（最后一个场景后不显示）
          if (index < this.userScenes.length - 1) {
            Divider()
              .strokeWidth(1)
              .color('#F0F0F0')
              .margin({ left: Spacing.LG, right: Spacing.LG })
          }
        })
        
        // 如果没有场景，显示提示
        if (this.userScenes.length === 0) {
          Text('暂无场景，点击下方按钮创建')
            .fontSize(FontSize.CAPTION1)
            .fontColor('#999999')
            .margin({ top: Spacing.MD, bottom: Spacing.MD })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      
      // 分隔线（在场景列表和创建按钮之间）
      Divider()
        .strokeWidth(1)
        .color('#F0F0F0')
        .margin({ left: Spacing.LG, right: Spacing.LG })
      
      // 居中的大按钮
      Row() {
        Text('+ 创建场景')
          .fontSize(FontSize.BODY1)
          .fontWeight(500)
          .fontColor('#007DFF') // 品牌蓝色
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: Spacing.LG })
      .onClick(() => {
        console.log('点击了创建场景按钮，跳转到创建场景页面')
        router.pushUrl({
          url: 'pages/SceneCreatePage'
        })
      })
    }
    .width('100%')
    .borderRadius(24) // 大圆角
    .backgroundColor('#FFFFFF') // 白色卡片
    .shadow({
      radius: 12,
      color: '#0F000000', // 浅阴影
      offsetX: 0,
      offsetY: 4
    })
  }

  // 推荐场景区域
  @Builder RecommendedScenesSection() {
    Column({ space: Spacing.LG }) {
      // 标题
      Text('推荐场景')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor('#000000')
        .alignSelf(ItemAlign.Start)
      
      // 推荐场景卡片列表
      Column({ space: Spacing.MD }) {
        ForEach(this.recommendedScenes, (scene: RecommendedScene) => {
          this.RecommendedSceneCard(scene)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // 单个推荐场景卡片
  @Builder RecommendedSceneCard(scene: RecommendedScene) {
    Stack() {
      // 背景图片（实际项目中应使用家居实景图，这里用渐变色模拟）
      Column()
        .width('100%')
        .height(180)
        .borderRadius(24) // 大圆角
        .linearGradient({
          angle: 135,
          colors: [
            [scene.gradientColors[0], 0],
            [scene.gradientColors[1], 1]
          ]
        })
        .opacity(0.9) // 背景图透明度
      
      // 渐变蒙版（低透明度同色系叠加）
      Column()
        .width('100%')
        .height(180)
        .borderRadius(24)
        .linearGradient({
          angle: 135,
          colors: [
            [scene.gradientColors[0] + '99', 0], // 60% 透明度
            [scene.gradientColors[1] + '99', 1]
          ]
        })
      
      // 内容区域
      Column({ space: Spacing.SM }) {
        // 标题和描述
        Column({ space: 6 }) {
          Text(scene.title)
            .fontSize(20)
            .fontWeight(700)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 2 })
          
          Text(scene.description)
            .fontSize(FontSize.CAPTION1)
            .fontColor('rgba(255, 255, 255, 0.95)')
            .textAlign(TextAlign.Start)
            .lineHeight(18)
        }
        .alignSelf(ItemAlign.Start)
        .margin({ left: Spacing.LG, top: Spacing.LG })
        
        // 设备标签（左下角）
        Row({ space: Spacing.XS }) {
          ForEach(scene.tags, (tag: string) => {
            Text(tag)
              .fontSize(FontSize.CAPTION2)
              .fontColor('#FFFFFF')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16) // 圆角按钮
              .backgroundColor('rgba(255, 255, 255, 0.25)')
              .margin({ bottom: Spacing.MD })
          })
        }
        .alignSelf(ItemAlign.Start)
        .margin({ left: Spacing.LG, bottom: Spacing.LG })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(180)
    .borderRadius(24) // 大圆角
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      console.log(`点击了推荐场景: ${scene.title}`)
      // 跳转到场景详情页
      router.pushUrl({
        url: 'pages/SceneDetailPage',
        params: { sceneId: scene.id }
      })
    })
  }
}