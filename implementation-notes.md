# Nemo iOS 骨架与导航实现台账

## 1. 计划与实现偏差（Deviations & Real Alignment）
- **全面对齐 Android 真实源码文案与结构**：
  - 彻底剔除了上一轮骨架中 AI 自行脑补的虚构文案（如“JLPT N2 核心词汇”、“记忆巩固贴士”、“阶段 1·新接触”等）。
  - **学习主页（LearningHomeView）** 100% 对齐 Android `HomeScreen.kt`：
    - 顶部欢迎：`Hi, [用户名] さん` + 早中晚动态时段问候语 + 用户头像；
    - 核心 Bento Grid：打卡天数徽章 + 单词/语法模式切换器（`LearningMode`）+ 环形今日新学进度与目标 + 待复习进度（`已复习/待复习数`）+ 学习达成率（`%`）+ 开始今日学习主胶囊按钮；
    - 学习资源分区：热力图（记录每日学习足迹）+ 五十音图（平假名与片假名）+ 动词活用（13种变形速查）+ AI工坊（造句与翻译实时批改）+ AI阅读（分级智能短文）。
  - **进度仪表盘（ProgressHomeView）** 100% 对齐 Android `ProgressDashboardScreen.kt`：
    - 学习摘要大卡片：总掌握、今日已学/目标、待复习项、总体掌握度进度条；
    - 统计与分析：今日统计、历史统计、遗忘曲线、学习日历；
    - 资料与词库：单词列表、语法列表、分类词汇、地道表达；
    - 强化与突破：分类练习、难点攻坚。
  - **测试大厅（TestHomeView）** 100% 对齐 Android `TestDashboardScreen.kt`：
    - 今日战报大卡片：今日已测题目、连续自测天数、累计测试总数、正确率；
    - 复习与巩固：错题集（XX 项待复习）、收藏夹（XX 项已收藏）；
    - 基础练习模式：单选测试（四选一快速辨析）、拼写测试（键盘输入假名拼写）、卡片连线（假名与释义配对消除）、语法排序（语境词块拖拽还原）；
    - 其他能力强化：能力工坊（听力辨析、动词变形与完形填空综合实战）。
  - **设置主页（SettingsHomeView）** 100% 对齐 Android `SettingsScreen.kt`：
    - 账户与同步、主题与外观、学习设置（每日新词目标/每日语法目标/记忆算法模型/每日重置时间）、语音发音（TTS发音人、自动朗读开关、语速Slider）、数据管理（导出/导入/存储空间/重置）、实验室（液态玻璃实验室、圆角曲率实验室）、关于 Nemo。

- **跨平台色彩兼容增强（消除 Xcode Preview 编译报错）**：
  - 在 `NemoCard.swift` 中封装了 `Color.nemoGroupedBackground`、`Color.nemoSecondaryGroupedBackground`、`Color.nemoTertiaryGroupedBackground`；
  - 自动根据目标环境自适应（iOS 下使用 UIKit 原生语义色彩，Mac 目标下使用 AppKit 原生语义色彩），彻底杜绝了 Xcode 在目标设备为 `My Mac` 或模拟器时报 `systemGroupedBackground` 无法推断的错误。

- **底部导航栏 Tab 真实文案与图标对齐（彻底清理旧变量名带偏）**：
  - 原 Android 代码底层枚举历史残留名为 `LEARNING` 与 `SETTINGS`，但 Android 真实 `strings.xml` 中显示的文案为：
    - Tab 1: **“主页”**（`core_bottombar_tab_learning`，图标 `Home` ➔ iOS: `house.fill`）
    - Tab 2: **“进度”**（`core_bottombar_tab_progress`，图标 `BarChart` ➔ iOS: `chart.bar.fill`）
    - Tab 3: **“测试”**（`core_bottombar_tab_test`，图标 `Interests` ➔ iOS: `sparkles`）
    - Tab 4: **“个人”**（`core_bottombar_tab_settings`，图标 `AccountCircle` ➔ iOS: `person.crop.circle.fill`）
  - 现已在 `ContentView.swift` 中 100% 修正为【主页、进度、测试、个人】，彻底摒弃旧代码中的“学习”与“设置”。

- **各模块导航标题（navigationTitle）全面重构为纯正 Apple HIG 规范**：
  - 彻底清理“进度仪表盘”、“测试大厅”等冗余生硬文案：
    - 主页（`LearningHomeView`）：移除硬编码大标题，设置 `.toolbar(.hidden, for: .navigationBar)`，使“Hi, Nemo さん”问候区通顶一体化展现；
    - 进度（`ProgressHomeView`）：大标题精简为纯粹双字 **“进度”**，支持 iOS 原生下滑展开、上滑折叠收缩；
    - 测试（`TestHomeView`）：大标题精简为纯粹双字 **“测试”**，支持 iOS 原生折叠；
    - 个人（`SettingsHomeView`）：大标题修正为 **“个人”**，100% 呼应底部 Tab。

- **Bento Grid 核心便当盒网格左右列高度严格平齐重构**：
  - 修复此前左侧“今日新学进度”卡片自然高度（约180pt）小于右侧双卡片之和（约228pt）导致的下沿悬空落差缺陷；
  - 引入 `RightColumnHeightPreferenceKey` 与 `GeometryReader` 动态测量右侧列高度，并动态绑定至左侧大卡片；
  - 左侧卡片内部使用 `Spacer(minLength: 8)` 实现环形进度指示器绝对纵向垂直居中，底边与右侧第二张卡片完全水平对齐。

- **Bento 5 主行动按钮 100% 对齐 Clash-Client 源码与 Apple 原生系统规范**：
  - **彻底移除自捏伪材质与大光晕**：彻底删除上一轮手写的 `.ultraThinMaterial`、双层半透明渐变以及 `.shadow(color: tintColor.opacity(0.32), radius: 14)`。该手写阴影在真机浅灰底色（`#F2F2F7`）下会产生严重扩散的脏橙色污渍色块；
  - **100% 原生对齐 Clash-Client 官方实现（`ClashButtonStyles.swift`）**：
    - 采用 Apple 原生标准 `.buttonStyle(.borderedProminent)`；
    - 采用原生胶囊轮廓 `.buttonBorderShape(.capsule)` 与 `.controlSize(.regular)`；
    - 标签保留文案与图标（`继续学习` / `立即开始`），结合 Nemo 品牌配色动态自适应（单词模式：`Color.orange`，语法模式：`Color.green`）；
  - **视觉与交互效果**：表面色彩纯正饱满、轮廓利落，彻底杜绝脏雾化与伪描边，按压具有纯正 Apple 原生微暗与触觉反馈，与 Clash-Client 100% 一致。
  - 苹果液态玻璃核心特征：顶部曲面漫反射微光（Surface Sheen）+ 微米级边缘镜面高光反射切角边框（Specular Highlight Rim）；
  - 真正的物理交汇互动（Direct Manipulation）：
    - 手指触碰按下时，触发苹果原生物理弹簧压缩动效（`interpolatingSpring` 比例 0.965）；
    - 玻璃材质在压力下光学浓度自然加深（模拟真实物理受力透镜表现）；
    - 硬件级 Taptic Engine（`UIImpactFeedbackGenerator(.medium)`）即时触觉回馈；
  - 文案与状态动态响应：未学时呈现 **“立即开始”**（`play.fill`），已学时无缝切换为 **“继续学习”**（`arrow.right`）。

- **进度主页（ProgressHomeView）顶部轮播学习摘要卡片 100% 对齐 Android `LearningSummaryCard`**：
  - 彻底替换原有简陋单一的静态卡片，提炼独立组件 `LearningSummaryCarouselCard.swift`；
  - 完整实现 3 页 Bento Grid（便当盒栅格）轮播：
    1. **日间概览（Daily Overview）**：`Color.blue` 主题，`calendar.badge.clock` 水印，主指标“今日已学”（项）+ 迷你进度条，副指标“待复习”（项）与“目标完成度”（%）；
    2. **学习轨迹（Learning Track）**：`Color.green` 主题，`chart.xyaxis.line` 水印，主指标“连续学习”（天）+ 7 日打卡点阵，副指标“累计掌握”（项）与“待学习”（项）；
    3. **成长总览（Growth Overview）**：`Color.orange` 主题，`chart.line.uptrend.xyaxis` 水印，主指标“总进度”（%）+ 4 柱微型趋势条，副指标“累计学习”（天）与“本周学习”（天）；
  - **动态联动指示器**：底部居中实现苹果风格动态滑动胶囊指示器，激活项自适应当前页主题色平滑伸缩；
  - **无泄漏生命周期并发调度**：采用 `.task` 异步循环与 `Task.sleep(for: .seconds(5))` 驱动 5 秒自动轮播，视图销毁或离开时由系统自动取消。
- **主页（LearningHomeView）Bento 5 主操作按钮升级为【全胶囊 + 纯正苹果官方液态玻璃材质】**：
  - **主按钮 100% 复用 Clash-Client 源码逻辑（STUNTest / 开始测试同款架构）**：
    - 直接复用 `clashPrimaryActionButtonStyle()` 核心源码：
      ```swift
      if #available(iOS 26.0, macOS 26.0, tvOS 26.0, *) {
          return AnyView(buttonStyle(.glassProminent))
      }
      return AnyView(buttonStyle(.borderedProminent))
      ```
    - 在用户当前的 iOS 26/27 系统上，直接触发苹果官方最新的系统级 `.glassProminent` 原生液态玻璃按钮样式；在旧版本上优雅降级为 `.borderedProminent`；
    - 搭配 Clash-Client 官方同款 `.nemoCapsuleButtonBorderShape()` 与苹果大按钮标准 `.controlSize(.large)`，将渲染总高度精准调升至 **50 pt**；
    - 文字升级为标准 `.font(.headline.weight(.bold))`，搭配 `.subheadline.weight(.bold)` 图标，内嵌 `minHeight: 38` 居中支撑；
    - 色彩与文案：仅将颜色替换为 Nemo 安卓原版色彩（单词模式：`Color.orange`，语法模式：`Color.green`），文案为 `继续学习` / `立即开始`。
- **进度列表行设计 100% 对齐 Clash-Client 官方参数体系**：
  - 图标容器：由原 38×38pt 替换为苹果标准 `29 × 29 pt`，搭配 G2 连续圆角 `9 pt` 与纯白 `.body.weight(.semibold)` 图标（比例约为 0.58 : 1）；
  - 间距与行高：图标与文本间距设为 `12 pt`，整行设定基线最小高度 `63 pt`，垂直内边距为 `8 pt`；
  - 排版与层级：主标题升级为 `.font(.body)`（17pt），副标题采用针对中文优化的 `.font(.footnote)`（13pt），中文字形上下留白间距精确设定为 `5 pt`；
  - 展开与分割：右侧箭头采用 `chevron.forward`（`.footnote.weight(.semibold)`），分割线左侧缩进对齐文本起点（`49 pt`）。
- **主题与外观界面（ThemeSettingsView）与 8 款流体玻璃图标 100% 落地**：
  - **入口页导航联动**：在 `SettingsHomeView.swift` 中将原行内 Picker 升级为原生 `NavigationLink` 入口行，配备紫色圆角矩形图标井、主标题与当前状态副标题；
  - **三大显示与定制分区**：
    1. **显示模式**：浅色/深色双微缩卡片网格切换、自动切换开关、跟随系统/定时切换策略；
    2. **个性化定制**：5 色主题强调色切换（薄荷绿/活力橙/旗舰蓝/赛博紫/樱花粉）、设置项图标风格切换（柔和半透/鲜活纯色）；
    3. **8 款 Apple 原生流体玻璃桌面图标选择器**：横向滚动卡片，展示薄荷翠绿、黑曜透亮、旗舰冰蓝、鲜活亮橙、樱花透粉、赛博幻紫、珊瑚暖红、璨金阳光；
  - **系统级 Alternate Icons 支持**：
    - 在 `project.pbxproj` 中启用 `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`；
    - 将 8 款 1024×1024 完整尺寸图标打包注入 `Assets.xcassets`，同时支持应用内高清渲染与桌面动态换图标（`UIApplication.shared.setAlternateIconName`）。
- **Xcode 自动化编译与 IPA 生成通过**：
  - 借助 Windows 宿主机与 macOS 虚拟机（VMware）混合架构，通过 `vmrun` 管道完成无签名 Release 构建与 IPA 打包；
  - 编译状态：`** BUILD SUCCEEDED **`，exit code 0；
  - 最新产物：`E:\Nemo\Nemo.ipa`（最新时间戳 2026/11/22 01:14，大小约 8.3 MB，已打包全部 8 款高清流体玻璃图标、ThemeSettingsView 与 50pt 胶囊主按钮），可直接导入爱思助手进行个人证书自签安装。

## 2. 待复核与后续推进问题（Questions for Review）
- **SRS 数据持久化与网络接入**：下一步待用户确定时，将这 4 大界面的响应式 `@State` 状态平滑接入 Swift 原生 `@Observable FeatureStore` 与 Supabase 网络/本地 SQLite 数据库。
