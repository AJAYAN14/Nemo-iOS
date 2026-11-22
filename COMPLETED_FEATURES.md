# Nemo iOS 已实现功能与架构全景档案 (Completed Features Specification)

> **文档定位**：本文件记录 Nemo iOS 工程自立项起已完整实现、编译通过并验证交付的所有功能、界面结构、设计参数、资源配置及底层架构。**供后续开发与 AI 审查直接读取，无需重复逐行排查已有代码**。
> **最后更新时间**：2026-11-22
> **工程版本**：Nemo 1.0.0 Dev (Build 2601) / 对齐 Android Nemo 2.0 架构
> **代码仓库**：[https://github.com/AJAYAN14/Nemo-iOS](https://github.com/AJAYAN14/Nemo-iOS) (branch: `main`)
> **本地产物**：`E:\Nemo\Nemo.ipa` (Release 无签名 IPA，支持爱思助手个人证书签名自装)

---

## 一、工程基础设施与技术栈

### 1. 技术栈与环境
* **开发语言**：Swift 6
* **UI 框架**：SwiftUI（100% 原生声明式架构，全量采用 `.sensoryFeedback` 触觉调度、`Gauge` 仪表盘、`Grid` 网格布局及 `ProgressView` 原生控件；搭配必要系统级 API 如 `UIApplication.shared.setAlternateIconName`）
* **支持系统**：iOS 16.0 ~ iOS 26.5+ (基准 Target: 26.5)
* **项目组织**：Xcode 16 PBXFileSystemSynchronizedRootGroup（自动同步磁盘物理目录，新增 Swift 源码自动参与编译）
* **编译打包流程**：
  - Windows 宿主机与 VMware macOS 虚拟机双工通信；
  - 自动化脚本清洗 Extended Attributes (`._` 文件与 `.DS_Store`) 并归档；
  - `vmrun` 管道调用虚拟机运行无签名 Release 构建与 IPA 打包；
  - 产物自动回传至宿主机 `E:\Nemo\Nemo.ipa`，并自动 Git Commit & Push 至 GitHub。

### 2. 工程目录结构
```
E:\Nemo\iOS\Nemo\
├── Nemo.xcodeproj/                     # Xcode 工程配置文件
├── Nemo/
│   ├── NemoApp.swift                   # 应用主入口，全局外观管理与启动屏交叉淡出转场
│   ├── ContentView.swift               # 顶层 4-Tab 导航容器 (主页、进度、测试、个人)
│   ├── Assets.xcassets/                # 高清资产库 (包含 8 套流体玻璃 AppIcon 及 NemoSplashLogo 图集)
│   ├── Core/
│   │   └── UI/
│   │       ├── Components/
│   │       │   ├── NemoSplashView.swift            # 全新品牌启动屏 (深海呼吸光晕 + 6浮动几何体 + Welcome!逐字弹跳 + 底部Logo展开)
│   │       │   ├── NemoCard.swift                  # G2 连续圆角卡片容器与跨平台语义色彩扩展
│   │       │   ├── NemoSectionHeader.swift         # 全局统一 17pt Bold Primary 卡片大标题组件
│   │       │   └── NemoPressableButtonStyle.swift  # 物理弹簧缩放与触觉反馈按钮样式
│   │       └── Extensions/
│   │           ├── Color+NemoTheme.swift           # 系统级分组背景与启动屏专属语义色彩
│   │           └── View+NemoStyles.swift           # 行动按钮与胶囊轮廓公共修饰符
│   └── Features/
│       ├── Learning/
│       │   └── LearningHomeView.swift              # 学习主页 (Bento 栅格 + 学习资源)
│       ├── Progress/
│       │   ├── ProgressHomeView.swift              # 进度仪表盘 (统计分析 + 词库列表)
│       │   └── LearningSummaryCarouselCard.swift   # 顶部 3 页轮播 Bento Grid 学习摘要大卡片
│       ├── Test/
│       │   └── TestHomeView.swift                  # 测试大厅 (战报卡片 + 4 类基础练习入口)
│       └── Settings/
│           ├── SettingsHomeView.swift              # 个人设置主页 (账户、外观、学习、发音、数据)
│           └── ThemeSettingsView.swift             # 主题与外观子页 (iPhone 比例微缩机身 + 8款动态图标)
├── implementation-notes.md             # 实施变更记录台账
└── COMPLETED_FEATURES.md               # 本档案 (已实现功能完整索引)
```

---

## 二、全新品牌启动屏实现全貌 (`NemoSplashView.swift`)

* **设计定位与规范**：面向 iOS 27 / 现代 iOS 原生标准开发，100% 复刻 Android Nemo 开屏品牌微动效，严格遵循 Apple HIG 启动屏无缝平滑交接准则。
* **冷启动静态底色与 Logo 无缝交接（Zero-Jitter Hand-off）**：
  - Xcode 自动生成轻量级启动屏配置，浅色纯白、深色纯黑；
  - 启动第一帧与 SwiftUI `NemoSplashView` 像素级重合，彻底杜绝闪黑或跳动。
* **中央舞台核心微动效**：
  1. **深海呼吸环境光晕 (Ambient Aurora Glow)**：
     - 460pt 尺寸，配合 48pt Blur 彻底消融边界；
     - 采用多阶平滑指数衰减双径向渐变（深色：`nemoSplashGlowSky` + `nemoSplashGlowTeal`，浅色：`nemoSplashGlowLightBlue` + `nemoSplashGlowOrange`）；
     - 4.2 秒周期循环平滑呼吸缩放（0.88 ~ 1.14）与微旋转（-4° ~ 6°）。
  2. **四周 6 组漂浮彩色小几何体**：
     - 精准贝塞尔矢量图形（`HeartShape`、`TriangleShape`、`RoundedRectangle`）；
     - 120ms~460ms 依次弹跳入场，随后进入各自独立周期（3.2s~4.0s）的微悬浮浮动（-8pt）与微旋转（14°）。
  3. **中央 "Welcome!" 英文与微笑弧线**：
     - 8 个字符以 55ms 递增步进弹跳弹出（位移、缩放、微旋转、淡入）；
     - 微笑贝塞尔弧线（`SmileArcShape`）顺滑从左到右描边生长（0 -> 1）。
* **底部品牌锁（Brand Lockup）**：
  - 60×60pt 品牌 Logo：100ms 弹出 -> 550ms 执行 Push 弹簧微抖反馈，并伴随系统触觉引擎微震动（`.sensoryFeedback(.impact(weight: .light))`）；
  - 同时展开间隙、竖向分割线生长拉伸，遮罩平滑滑出加粗 32pt "Nemo" 英文。
* **平滑交叉转场与无障碍支持**：
  - 2.4 秒动效自然就位后触发回调，通过 `NemoApp.swift` 执行 0.45 秒平滑 Crossfade 进入主页 `ContentView`；
  - 底座视图预挂载，转场零卡顿；
  - 自动响应 `@Environment(\.accessibilityReduceMotion)`，开启减弱动效时自动跳过剧烈弹跳与浮动，以轻柔渐变优雅过渡。

---

## 三、四大主界面实现全貌 (100% 对齐 Android Nemo)

### 1. 学习主页 (`LearningHomeView.swift`)
* **导航栏设定**：`.toolbar(.hidden, for: .navigationBar)`，通顶沉浸展示；
* **顶部用户欢迎栏**：
  - `Hi, Nemo さん`（`title2.heavy` 衬线体）；
  - 早中晚动态时段自适应问候语（早晨、午后、傍晚、深夜动态匹配）；
  - 用户头像微缩徽章；
* **核心 Bento Grid（便当盒栅格）**：
  - **连续打卡徽章**：展示打卡天数（如 `12 天`）；
  - **学习模式切换器**：单词 / 语法（`LearningMode`）分段控制器，切换时全页面品牌主色即时响应（单词模式：`Color.orange`，语法模式：`Color.green`）；
  - **今日新学进度大卡片**：采用苹果官方原生 **`Gauge(value:in:)`** 搭配 `.gaugeStyle(.accessoryCircularCapacity)`，原生支持 VoiceOver 无障碍读屏，中间展示新学完成数，底部展示新学目标；
  - **辅助进度指示卡片**：复习进度（`已复习/总待复习`）、学习达成率（`%`）；
  - **左右列高度绝对对齐**：采用 iOS 16+ 原生 **`Grid` 与 `GridRow`** 容器原生对齐，彻底废弃 `GeometryReader` 与 `PreferenceKey` 测量，消除二次布局回流开销；
  - **Bento 5 主行动胶囊按钮**：
    - 高度 50 pt，原生全胶囊轮廓；
    - 针对 iOS 26+ 优先触发原生 `.glassProminent` 液态玻璃样式，旧版本平滑降级 `.borderedProminent`；
    - 文案根据学习进度动态流转：未学时显示“立即开始”，已学时自动切换为“继续学习”；
* **学习资源分区**：
  - 使用全局 `NemoSectionHeader("学习资源")`；
  - 热力图横幅卡片：展示学习足迹热力网格；
  - 四大独立资源双列网格：五十音图（清音/浊音）、动词活用（13种活用变形）、AI工坊（智能造句与翻译）、AI阅读（智能短文精读）。

---

### 2. 进度仪表盘 (`ProgressHomeView.swift`)
* **导航标题**：纯正双字 **“进度”**，支持 iOS 原生下滑展开、上滑折叠；
* **顶部轮播学习摘要卡片 (`LearningSummaryCarouselCard.swift`)**：
  - **3 页 Bento Grid 自动轮播**：
    1. *日间概览（Daily Overview）*：蓝色主题，时钟水印，主指标今日已学，副指标待复习项与目标完成度；
    2. *学习轨迹（Learning Track）*：绿色主题，折线水印，主指标连续学习天数，7 日打卡点阵，累计掌握；
    3. *成长总览（Growth Overview）*：橙色主题，趋势水印，主指标总掌握度进度，4 柱微型趋势条；
  - 底部居中实现苹果风格动态滑动胶囊指示器，激活项自适应当前页主题色伸缩；
  - 生命周期安全：`.task` 异步调度 5 秒自动轮播，离开视图自动销毁，零内存泄漏；
* **功能分区列表行（100% 对齐 Clash-Client 官方参数规范）**：
  - 统计与分析：今日统计、历史统计、遗忘曲线、学习日历；
  - 资料与词库：单词列表、语法列表、分类词汇、地道表达；
  - 强化与突破：分类练习、难点攻坚；
  - 参数规范：29×29 pt G2 连续圆角图标井 + 17pt body 标题 + 13pt footnote 副标题 + 5pt 中文字间距 + 右侧 `chevron.forward`。

---

### 3. 测试大厅 (`TestHomeView.swift`)
* **导航标题**：纯正双字 **“测试”**，支持 iOS 原生折叠；
* **今日战报卡片**：
  - 胶囊型正确率标签（如 `正确率 85%`）；
  - 三栏核心指标：今日已测题目、连续自测天数（橙色突出）、累计测试总数（紫靛色突出）；
* **三大功能分区**：
  - `NemoSectionHeader("复习与巩固")`：错题集卡片、收藏夹卡片；
  - `NemoSectionHeader("基础练习模式")`：单选测试（四选一）、拼写测试（假名拼写）、卡片连线（配对消除）、语法排序（词块拖拽）；
  - `NemoSectionHeader("其他能力强化")`：能力工坊（听力辨析、动词变形、完形填空综合实战）。

---

### 4. 个人设置主页 (`SettingsHomeView.swift`)
* **导航标题**：大标题模式 `.navigationBarTitleDisplayMode(.large)`，文案 **“个人”**；
* **分区 1：账户与同步**
  - 登录状态卡片：用户头像、昵称、“账号同步已开启”；
  - “备份至云端”、“云端备份历史”操作行；
* **分区 2：主题与外观**
  - 原生 `NavigationLink` 入口，紫色圆角图标井，右侧副标题动态显示当前外观模式（`浅色模式` / `深色模式` / `跟随系统`）；
* **分区 3：学习设置（100% 对齐 Android 源码）**
  - **每日单词目标**：橙色目标图标，参数严格为 `[5, 10, 20, 30, 50]`，格式 `X个`（默认 `20个`）；
  - **每日语法目标**：绿色书本图标，参数严格为 `[5, 10, 15, 20, 25]`，格式 `X条`（默认 `10条`）；
  - **学习日重置时间**：薄荷绿时钟图标，参数严格为 `[0, 2, 4, 5, 6]`，对应文案：
    - `0` ➔ `凌晨 0:00 (午夜)`
    - `2` ➔ `凌晨 2:00`
    - `4` ➔ `凌晨 4:00 (推荐)`（默认）
    - `5` ➔ `凌晨 5:00`
    - `6` ➔ `凌晨 6:00`
  - **新内容乱序抽取**：青蓝色随机图标，原生 iOS Switch 开关，开启展示“随机抽取新内容”，关闭展示“按顺序抽取新内容”，持久化绑定；
  - **记忆算法配置**：紫色芯片图标，副标题“步进、提前复习与 Leech 策略”，带跳转箭头；
  - **AI 工坊配置**：蓝色星光图标，副标题“设置 API Key 与 AI 模型”，带跳转箭头；
* **分区 4：语音发音**
  - 单行独立导航入口「语音设置 >」（粉色扬声器圆角图标井），跳转至原生二级子界面 `TtsSettingsView`；
  - 彻底移除了“翻卡自动朗读”（保证界面纯洁性）；
  - 支持原生发音人选择（`Picker(.navigationLink)`）、标准乌龟兔子语速调节、音调调节、双语例句试听与默认重置。
* **分区 5：数据管理**
  - 导出学习数据、导入学习数据、存储空间占用统计（14.2 MB）、重置学习数据（红色 Destructive 按钮）；
* **分区 6：关于 Nemo**
  - 应用版本（`1.0.0 Dev (Build 2601)`）、技术底座（`SwiftUI · Swift 6`）、工程定位（`纯个人自用 (免 App Store 审核)`）；
  - 移除已由 iOS 系统原生支持的“实验室”多余分区。

---

## 三、主题外观与流体玻璃图标系统 (`ThemeSettingsView.swift`)

### 1. 核心交互与动画体验
* **子界面底栏智能收起动效**：
  - 应用 `.toolbar(isTabBarHidden ? .hidden : .visible, for: .tabBar)`；
  - 绑定物理弹簧动画 `.animation(.spring(response: 0.38, dampingFraction: 0.82), value: isTabBarHidden)`；
  - 进入页面时底栏**平滑下沉隐去**，返回主界面时**自然回弹上浮**，仅在四个主界面展示导航底栏。
* **分割线修复**：
  - 针对预览卡片行与自动切换行配置 `.listRowSeparator(.hidden)`，彻底消除了由于居中占位导致的断裂残存分割线，卡片浑然一体。

### 2. 真实 iPhone 宽高比 (9:19.5) 微缩机身模型
* **外观尺寸**：88 × 180 pt 黄金机身比例；
* **精密细节还原**：
  - G2 平滑连续圆角机身边框（20 pt）+ 微金属高光边缘线；
  - 顶部灵动岛（Dynamic Island，黑色胶囊条）；
  - 屏幕内部微缩元素：迷你导航栏、Nemo 卡片、列表占位条、底栏 4 Tab 圆点；
  - 底部 Home Indicator（主屏幕触控条）；
  - 选中状态带有品牌强调色的外轮廓发光环与单选圆环。

### 3. Apple HIG 原生深浅色模式规范
* **全局同步机制**：`NemoApp.swift` 顶层挂载 `.preferredColorScheme(currentColorScheme)`，全 App 视图与弹窗毫秒级无缝联动；
* **自动模式逻辑**：
  - 跟随系统：直接继承 iOS 系统全局日出日落或控制中心切换；
  - 自定时段：**100% 苹果官方原生 `DatePicker`**（包含“深色开始时间”与“深色结束时间”），点击唤起 iOS 官方时间转轮与数字小键盘，支持跨天时段（如 21:00 ~ 07:00）自动计算。

### 4. 8 款专为 Apple 打造的高清流体玻璃图标库
* **默认图标**：**Apple-blue（旗舰冰蓝）**，100% 对齐 Android Nemo 默认配置；
* **8 色流体玻璃全阵容**：
  1. `Apple-blue`（旗舰冰蓝 · 经典旗舰蓝宝石）➔ 默认主图标
  2. `Apple-black`（黑曜透亮 · 黑曜石通透高光）
  3. `Apple-green`（薄荷翠绿 · 薄荷翠绿微光）
  4. `Apple-orange`（鲜活亮橙 · 明快活力橙）
  5. `Apple-pink`（樱花透粉 · 轻盈樱粉晶莹）
  6. `Apple-purple`（赛博幻紫 · 赛博流体幻紫）
  7. `Apple-red`（珊瑚暖红 · 热烈珊瑚红）
  8. `Apple-yellow`（璨金阳光 · 温暖璨金阳光）
* **动态更换技术方案**：
  - `Assets.xcassets` 中注入全套 1024×1024 图标源文件与多倍率切片；
  - Xcode 构建配置开启 `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`；
  - 编译期自动生成 `Info.plist` 中的 `CFBundleAlternateIcons` 配置；
  - 运行时调用 `UIApplication.shared.setAlternateIconName` 实现实时桌面图标更换。

---

## 四、全局统一设计组件库 (`Core/UI/Components`)

### 1. `NemoSectionHeader.swift` (卡片大标题)
* **规范**：遵循 Apple HIG 方案 A 规范；
* **排版规格**：**`Headline`（17 pt）+ `Bold` 粗体**（`.font(.headline.weight(.bold))`）；
* **色彩机制**：自适应深浅色高对比度 **`.primary`**（浅色纯黑、深色纯白）；
* **全应用 5 大页面统一覆盖**：个人设置、主题外观、学习主页、进度主页、测试主页所有内容卡片上方标题均由其统一接管。

### 2. `NemoCard.swift` (标准圆角卡片容器)
* **曲率规范**：苹果 G2 连续平滑曲率（Continuous Corner Radius）；
* **语义色彩**：
  - 页面基底色：`Color.nemoGroupedBackground`（浅色 `#F2F2F7`，深色 `#000000`）；
  - 卡片抬升层：`Color.nemoSecondaryGroupedBackground`（浅色 `#FFFFFF`，深色 `#1C1C1E` 标准抬升层）；
  - 跨平台支持：iOS 环境自动映射 UIKit 语义色，Mac 环境映射 AppKit 语义色，彻底杜绝 Xcode 预览与不同目标设备编译报错。

### 3. `NemoPressableButtonStyle.swift` (微动效按钮样式)
* 模拟苹果真实物理按压弹簧缩放（0.965 系数）；
* 硬件级 Taptic Engine（`UIImpactFeedbackGenerator(.medium)`）即时触觉反馈。

---

## 五、状态持久化键名汇总表 (@AppStorage)

后续开发涉及状态存取时，直接复用以下统一的键名，避免重复定义导致的状态割裂：

| 键名 (Key) | 数据类型 | 默认值 | 作用描述 |
| :--- | :--- | :--- | :--- |
| `settings_dark_mode_option` | `String` | `"auto"` | 外观显示模式：`"auto"`, `"light"`, `"dark"` |
| `settings_auto_strategy` | `String` | `"follow_system"` | 外观自动策略：`"follow_system"`, `"scheduled"` |
| `settings_dark_start_time` | `String` | `"21:00"` | 自定时段深色开始时间 (`HH:mm`) |
| `settings_dark_end_time` | `String` | `"07:00"` | 自定时段深色结束时间 (`HH:mm`) |
| `settings_theme_accent` | `String` | `"薄荷绿"` | 主题强调色名称 |
| `settings_icon_style` | `String` | `"柔和半透"` | 设置项图标风格 |
| `settings_app_icon_option` | `String` | `"Apple-blue"` | 选中的桌面图标名称 |
| `settings_daily_word_goal` | `Int` | `20` | 每日单词新学目标数量 |
| `settings_daily_grammar_goal` | `Int` | `10` | 每日语法新学目标数量 |
| `settings_learning_day_reset_hour`| `Int` | `4` | 学习日重置刷新时点 (0, 2, 4, 5, 6) |
| `settings_random_extract_new_content` | `Bool` | `false` | 新内容是否乱序抽取 |
| `settings_tts_voice_name` | `String` | `"Kyoko"` | 选中的系统日语发音人代号 |
| `settings_tts_chinese_voice_name` | `String` | `"Tingting"` | 选中的系统中文发音人代号 |
| `settings_tts_speed` | `Double` | `1.0` | 语音朗读语速倍率 (0.5x ~ 2.0x) |
| `settings_tts_pitch` | `Double` | `1.0` | 语音朗读音调倍率 (0.5x ~ 2.0x) |

---

## 六、本次对话最新交付成果汇总 (2026-11-22)

### 1. 全工程 Apple DocC 规范与纯净血统治理
* **清理第三方与安卓元说明**：全面审查并清除了所有界面组件中的“对齐 Android”、“迁移自安卓”等口水套话与多余元说明；
* **采用 Apple 标准 DocC 注释规范**：全量代码均采用标准三斜线（`///`）文档注释，精确描述组件设计意图、参数范畴及返回值，契合 Apple 原生工程规范。

### 2. 深浅色模式切换生硬问题根治（系统级 0.35s 平滑交叉溶解）
* **痛点根因**：原先 `@AppStorage` 跨视图写入状态时丢失了 SwiftUI 动画事务，且 `UIWindow.overrideUserInterfaceStyle` 底层默认为 0ms 瞬间硬切，导致界面瞬间闪烁、极为刺眼；
* **系统级平滑解决方案**：
  1. 在 `NemoApp.swift` 根视图挂载 `.animation(.easeInOut(duration: 0.35), value: currentColorScheme)`；
  2. 在 `ThemeSettingsView.swift` 抽象统一的 `updateAppearance(to:)` 方法，直接触发原生 `UIView.transition(with: window, duration: 0.35, options: [.transitionCrossDissolve, .allowAnimatedContent])`；
  3. 点击外观卡片绑定 `.sensoryFeedback(.selection, trigger: isSelected)`；
* **效果达成**：深色与浅色之间实现如融雪般自然细腻的 0.35 秒平滑交叉溶解。

### 3. 主题色彩系统升级为 Apple HIG 10 款原生全景调色盘
* **扩充 10 款系统级强调色**：
  1. 旗舰蓝（`Color.blue`，系统默认）
  2. 极光青（`Color.cyan`）
  3. 晨曦青（`Color.teal`）
  4. 清爽薄荷（`Color.mint`）
  5. 生机绿（`Color.green`）
  6. 璨金黄（`Color.yellow`）
  7. 活力橙（`Color.orange`）
  8. 珊瑚红（`Color.red`）
  9. 樱花粉（`Color.pink`）
  10. 赛博紫（`Color.purple`）
* **网格交互**：由单行升级为 2 排 × 5 列自适应网格，选中项附带高光描边与打勾标记；
* **动态标题联动**：设置项右侧副标题实时响应并动态呈现当前选中的主题色名称。

### 4. 设置主页极简单行化与时间选择纯净化
* **消灭副标题与折行**：全面清理设置项行内副标题，杜绝多余文本占用横向空间导致的折行挤压，严格对齐 44pt 黄金等高规范；
* **重置时间纯净化**：重置时间选项彻底删除冗余中文括号（如“凌晨 4:00 (推荐)”），全部改为国际标准纯净时间格式：`00:00`、`02:00`、`04:00`、`05:00`、`06:00`；
* **说明下沉至 Footer**：将跨天保护等长文本规则统一下沉至 Section Footer 通栏灰字展示。

### 5. 语音设置（`TtsSettingsView.swift`）100% 苹果原生化与抽屉弹窗重构（对齐 Clash-Client 规范）
* **严格落实“有原生的就用原生的，不要自己写”，对齐成熟开源项目 `Clash-Client` 抽屉范式（`ClashProfilePickerCard` & `ClashSheetCloseButton`）**：
  - **原生抽屉弹窗（Bottom Sheet）**：发音人选择全面升级为 Apple 原生 `.sheet` 抽屉弹窗，配置 `.presentationDetents([.medium, .large])` 支持半屏/全屏自适应展开、`.presentationDragIndicator(.visible)` 原生系统把手胶囊与 `.presentationCornerRadius(24)` G2 连续顶部圆角；
  - **原生圆底关闭按钮**：淘汰传统文字式“完成”按钮，在右上角采用标准的浅灰色圆底加粗 `xmark` 原生关闭图标（`Circle().fill(Color(uiColor: .tertiarySystemFill))`），符合现代 iOS 原生抽屉交互规范；
  - **极简轻量化呈现**：彻底移除抽屉内嘈杂的 Footer 提示文字，列表纯净呈现；
  - **优雅单选与触觉反馈**：抽屉内采用 Inset Grouped 列表排版，展示发音人姓名与“女声 · 高保真”等标签，当前选中项右侧带有系统蓝色 Checkmark；点击即时保存至 `@AppStorage`、伴随系统触觉反馈（`.sensoryFeedback(.selection)`）并自动收起抽屉；
  - **宿主行尾指示器**：设置主界面的发音人行尾统一采用苹果标准 `chevron.forward` 展开指示箭头；
  - **动态系统音色**：基于原生 `AVSpeechSynthesisVoice.speechVoices()` 自动过滤并列举本地神经引擎已安装的发音人（Kyoko、Otoya、Siri、婷婷等）；
* **Apple 官方标志性语速滑块**：
  - 语速滑块两端接入 Apple 官方标准的乌龟（`Image(systemName: "tortoise.fill")`）与兔子（`Image(systemName: "hare.fill")`）辅助图标；
  - 音调滑块采用原生「低」与「高」标签；
* **彻底剔除私加内容**：
  - **彻底删除了此前私自添加的“翻卡自动朗读”**分区及相关变量，保持语音设置职责纯粹；
* **原生试听与重置**：
  - 采用原生 `Button` 承载双语例句试听（带播放/停止状态指示）；
  - 采用原生 `Button(role: .destructive)` 实现一键“恢复默认设置”。

### 6. 自动化编译验证与交付状态
* **构建脚本**：`build_ios.ps1` 管道自动化清理、推送虚拟机、执行无签名 Release 构建与 IPA 打包；
* **编译状态**：`xcodebuild Release` 0 报错通过；
* **交付产物**：`E:\Nemo\Nemo.ipa`（最新构建包约 8.9 MB）。

