/**
 * 场景页面 - 全新设计
 * 顶部：手机状态栏 + 页面标题「场景」+ 右上角黑色「+」按钮
 * 上半区：白色大圆角卡片「我的场景」
 * 下半区：推荐场景竖向卡片
 * 视觉风格：柔和简约家居风
 */
import { Colors, FontSize, Spacing, BorderRadius, ComponentSize, ThemeColors } from '../common/DesignConstants'
import router from '@ohos.router'
import { SceneStore, SceneModel } from '../SceneStore'


interface RecommendedScene {
  id: string
  title: string
  description: string
  tags: string[]
  gradientColors: string[]
  imageName: string
}

@Component
export struct ScenePage {
  @StorageLink('activeScene') activeScene: string = ''
  @StorageLink('userScenes') userScenes: SceneModel[] = []
  @StorageProp('isDarkMode') isDark: boolean = false
  
  @State private recommendedScenes: RecommendedScene[] = [
    {
      id: 'leave_home',
      title: '安心离家',
      description: '定义专属的离家场景，成为节能家居小达人',
      tags: ['开关', '灯', '空调'],
      gradientColors: ['#F5E6D3', '#D4B483'],
      imageName: 'scene_leave_home'
    },
    {
      id: 'alert',
      title: '异常警报',
      description: '感应到异常状态，立即告警和补救',
      tags: ['门磁传感器'],
      gradientColors: ['#FFD8CC', '#FF9A7A'],
      imageName: 'scene_alert'
    },
    {
      id: 'morning',
      title: '早起习惯',
      description: '养成健康生活习惯，开启元气一天',
      tags: ['灯', '空调', '空气净化器'],
      gradientColors: ['#FFF9E6', '#FFE699'],
      imageName: 'scene_morning'
    },
    {
      id: 'sleep',
      title: '就寝提醒',
      description: '按时早睡，营造舒适的睡眠环境',
      tags: ['灯', '插座', '开关'],
      gradientColors: ['#E8D9C5', '#B89B7D'],
      imageName: 'scene_sleep'
    },
    {
      id: 'back_home',
      title: '温馨回家',
      description: '定义专属的回家场景，享受悠闲的家庭时光',
      tags: ['空气净化器', '扫地机器人', '灯'],
      gradientColors: ['#F0F0F0', '#D9D9D9'],
      imageName: 'scene_back_home'
    }
  ]

  aboutToAppear(): void {
    SceneStore.initialize()
  }

  build() {
    Column() {
      this.StatusBarPlaceholder()
      this.TitleBar()
      
      Scroll() {
        Column({ space: Spacing.XL }) {
          this.MySceneCard()
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
    .backgroundColor(ThemeColors.bg(this.isDark))
  }

  @Builder StatusBarPlaceholder() {
    Row()
      .width('100%')
      .height(24)
  }

  @Builder TitleBar() {
    Row() {
      Text('场景')
        .fontSize(FontSize.TITLE1)
        .fontWeight(700)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .margin({ left: Spacing.LG })
      
      Blank()
      
      Text('+')
        .fontSize(32)
        .fontWeight(300)
        .fontColor(ThemeColors.textPrimary(this.isDark))
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
    .justifyContent(FlexAlign.Center)
  }

  @Builder MySceneCard() {
    Column({ space: Spacing.MD }) {
      Text('我的场景')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .margin({ left: Spacing.LG, top: Spacing.LG })
        .alignSelf(ItemAlign.Start)
      
      Column({ space: 0 }) {
        ForEach(this.userScenes, (scene: SceneModel, index: number) => {
          Row() {
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
                color: scene.color + '33',
                offsetX: 0,
                offsetY: 2
              }) {
              Text(scene.icon)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .fontWeight(700)
            }
            
            Column({ space: 4 }) {
              Text(scene.name)
                .fontSize(FontSize.BODY1)
                .fontWeight(500)
                .fontColor(ThemeColors.textPrimary(this.isDark))
              
              Text(scene.description || '暂无描述')
                .fontSize(FontSize.CAPTION1)
                .fontColor(ThemeColors.textSecondary(this.isDark))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .margin({ left: Spacing.MD })
            .layoutWeight(1)
            
            Text('›')
              .fontSize(24)
              .fontColor(ThemeColors.textTertiary(this.isDark))
              .margin({ right: Spacing.LG })
          }
          .width('100%')
          .height(60)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            console.log('点击场景:', scene.name)
            router.pushUrl({
              url: 'pages/SceneDetailPage',
              params: { sceneId: scene.id }
            })
          })
          
          if (index < this.userScenes.length - 1) {
            Divider()
              .strokeWidth(1)
              .color(ThemeColors.divider(this.isDark))
              .margin({ left: Spacing.LG, right: Spacing.LG })
          }
        })
        
        if (this.userScenes.length === 0) {
          Text('暂无场景，点击下方按钮创建')
            .fontSize(FontSize.CAPTION1)
            .fontColor(ThemeColors.textTertiary(this.isDark))
            .margin({ top: Spacing.MD, bottom: Spacing.MD })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      
      Divider()
        .strokeWidth(1)
        .color(ThemeColors.divider(this.isDark))
        .margin({ left: Spacing.LG, right: Spacing.LG })
      
      Row() {
        Text('+ 创建场景')
          .fontSize(FontSize.BODY1)
          .fontWeight(500)
          .fontColor(Colors.BRAND_PRIMARY)
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
    .borderRadius(24)
    .backgroundColor(ThemeColors.surface(this.isDark))
    .shadow({
      radius: 12,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder RecommendedScenesSection() {
    Column({ space: Spacing.LG }) {
      Text('推荐场景')
        .fontSize(FontSize.TITLE2)
        .fontWeight(600)
        .fontColor(ThemeColors.textPrimary(this.isDark))
        .alignSelf(ItemAlign.Start)
      
      Column({ space: Spacing.MD }) {
        ForEach(this.recommendedScenes, (scene: RecommendedScene) => {
          this.RecommendedSceneCard(scene)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder RecommendedSceneCard(scene: RecommendedScene) {
    Stack() {
      Column()
        .width('100%')
        .height(180)
        .borderRadius(24)
        .linearGradient({
          angle: 135,
          colors: [
            [scene.gradientColors[0], 0],
            [scene.gradientColors[1], 1]
          ]
        })
        .opacity(0.9)
      
      Column()
        .width('100%')
        .height(180)
        .borderRadius(24)
        .linearGradient({
          angle: 135,
          colors: [
            [scene.gradientColors[0] + '99', 0],
            [scene.gradientColors[1] + '99', 1]
          ]
        })
      
      Column({ space: Spacing.SM }) {
        Column({ space: 6 }) {
          Row() {
            Text(scene.title)
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#FFFFFF')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 2 })
              .layoutWeight(1)
            
            if (this.activeScene === scene.id) {
              Text('运行中')
                .fontSize(FontSize.CAPTION2)
                .fontColor('#FFFFFF')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(12)
                .backgroundColor('rgba(255, 255, 255, 0.35)')
            }
          }
          .width('100%')
          
          Text(scene.description)
            .fontSize(FontSize.CAPTION1)
            .fontColor('rgba(255, 255, 255, 0.95)')
            .textAlign(TextAlign.Start)
            .lineHeight(18)
        }
        .alignSelf(ItemAlign.Start)
        .margin({ left: Spacing.LG, top: Spacing.LG })
        
        Row({ space: Spacing.XS }) {
          ForEach(scene.tags, (tag: string) => {
            Text(tag)
              .fontSize(FontSize.CAPTION2)
              .fontColor('#FFFFFF')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
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
    .borderRadius(24)
    .shadow({
      radius: 8,
      color: ThemeColors.cardShadow(this.isDark),
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/SceneDetailPage',
        params: { sceneId: scene.id }
      })
    })
  }
}
