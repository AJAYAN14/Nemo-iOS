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
    - 账户与同步、主题与外观、学习设置、语音发音、数据管理、关于 Nemo。
    - 移除已由 iOS 系统级支持的实验室分区。

- **深浅色外观规范与 Apple HIG 严格对齐**：
  - 查阅 Apple Human Interface Guidelines - Dark Mode 核心准则：
    1. **优先尊重系统偏好 (Respect System Preferences)**：提供“自动/跟随系统”作为默认推荐，无缝响应 iOS 全局深浅色调度；
    2. **层级基底而非纯黑反色 (Elevation & Semantic Hierarchy)**：全量使用系统级语义背景 `systemGroupedBackground`（浅色 `#F2F2F7`，深色 `#000000`）与抬升卡片背景 `secondarySystemGroupedBackground`（浅色 `#FFFFFF`，深色 `#1C1C1E`）；
    3. **iPhone 原生机身宽高比 (9:19.5)**：预览卡片按 88×180pt 黄金比例重构，搭配灵动岛、状态栏、主屏幕微缩元素与底部 Home Bar 横条，直观复刻真实 iPhone；
    4. **全局统一调度**：在 `NemoApp.swift` 的 `WindowGroup` 挂载 `.preferredColorScheme(currentColorScheme)`，使四个主界面与所有弹窗全局毫秒级同步切换。

- **子界面隐藏底部导航栏（对齐 Android）**：
  - 在 `ThemeSettingsView` 等子页面应用 `.toolbar(.hidden, for: .tabBar)`；
  - 仅在 4 个根 Tab 界面（主页、进度、测试、个人）显示底部栏，进入子页面时原生收起，返回时丝滑展开。

- **个性化设置界面文字去重**：
  - 移除了设置项图标风格 Picker 内部的重复“图标风格”标签，仅在列表行首展示“设置项图标风格”，右侧呈现当前选项。

- **默认应用图标对齐 Android**：
  - 主图标默认设为旗舰冰蓝（`Apple-blue` / `DEFAULT`）；
  - `ThemeSettingsView` 默认选中冰蓝，调用 `UIApplication.shared.setAlternateIconName(nil)` 即可恢复系统默认图标，切换其他颜色调用对应的 `AppIcon-<color>`。

- **自动编译与 GitHub 仓库全链路交付**：
  - 代码库已完全推送到 GitHub: `https://github.com/AJAYAN14/Nemo-iOS.git`（commit `1a63cf0`）；
  - Release IPA 已构建完成并导出至 `E:\Nemo\Nemo.ipa`。
