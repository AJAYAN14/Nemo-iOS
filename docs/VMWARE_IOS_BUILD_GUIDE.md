# Windows + VMware macOS 混合架构 iOS 自动化编译与真机部署工程手册

> **项目**：Nemo iOS  
> **适用场景**：无苹果实体 Mac 电脑，在 Windows 宿主机开发，借助 VMware macOS 虚拟机 Xcode 进行编译打包，并通过 Windows 爱思助手直装 iPhone 真机。  
> **核心原则**：**编译与签名解耦**。虚拟机仅作为无签名编译器，宿主机负责个人证书签名与设备直装。

---

## 目录
1. [架构总览与核心设计](#1-架构总览与核心设计)
2. [重大暗坑与排雷纪要（必读）](#2-重大暗坑与排雷纪要必读)
3. [自动化编译流水线实现](#3-自动化编译流水线实现)
4. [Windows 端真机签名与部署指南](#4-windows-端真机签名与部署指南)
5. [Swift / SwiftUI 跨平台与规范要点](#5-swift--swiftui-跨平台与规范要点)
6. [一键全自动编译脚本](#6-一键全自动编译脚本)

---

## 1. 架构总览与核心设计

```
┌────────────────────────────────────────────────────────┐
│ 宿主机 (Windows 11)                                     │
│  - 源码开发与版本管理：E:\Nemo\iOS\Nemo                 │
│  - 调度中枢：Python 打包脚本 + VMware vmrun.exe CLI     │
│  - 产物落地：E:\Nemo\Nemo.ipa                           │
│  - 签名直装：爱思助手 (Apple ID 免费个人开发者证书)      │
└───────────────────────┬────────────────────────────────┘
                        │ vmrun CopyFileFromHostToGuest / ToHost
┌───────────────────────▼────────────────────────────────┐
│ 编译节点 (VMware Workstation - macOS Guest)            │
│  - macOS 版本：macOS 14+ / 15+ / 26+                   │
│  - 编译工具：Xcode.app (`xcodebuild` CLI)               │
│  - 工作空间：/Users/ajian/Desktop/NemoWorkspace        │
│  - 核心参数：CODE_SIGNING_ALLOWED=NO                   │
└────────────────────────────────────────────────────────┘
                        │ 爱思助手 USB / Wi-Fi 直连安装
┌───────────────────────▼────────────────────────────────┐
│ 运行终端 (iPhone 真机)                                  │
│  - 系统版本：iOS 17+ / 18+ (无需越狱，无需巨魔)         │
│  - 运行机制：苹果官方「个人开发者免费证书 (7天循环免越狱)」│
└────────────────────────────────────────────────────────┘
```

---

## 2. 重大暗坑与排雷纪要（必读）

### 陷阱 1：虚拟机内硬刚 Apple ID 登录死局
- **现象**：在虚拟机 macOS 的“系统设置”或 Xcode 中登录 Apple ID，弹出警告或加载死循环，抓包显示报错 `NSXMLParserErrorDomain 错误 111 (Line 7, column 8)`。
- **原因**：VMware 虚拟机的虚拟 NVRAM 中，ROM 字段普遍携带 `VM` 虚拟化字符串（如 `VM%071%e4%a1`），且序列号为公共黑名单，缺乏苹果物理 T2 安全芯片与免驱蓝牙硬件指纹。苹果 GSA 鉴权服务器在 TLS 握手后直接拦截，返回一段 7 行的 HTML 401 页面。系统底层 XML 解析器在第 7 行第 8 列解析 `</html>` 时崩溃。
- **解法**：**彻底放弃在虚拟机内登录 Apple ID**。Xcode 原生支持纯离线编译，不需要 Apple ID 也能编译出完整的二进制代码。

### 陷阱 2：改动 VMware 内核伪装导致虚拟机崩溃
- **现象**：在 `.vmx` 配置文件中强加 `hypervisor.cpuid.v0 = "FALSE"` 试图屏蔽虚拟机特征，开机直接触发 `0xc0000005` 崩溃秒退。
- **原因**：VMware 17.5+ 运行 macOS 客户机时部分指令集高度依赖宿主机 Hypervisor 层调度，强行隐藏会导致底层未处理异常。
- **解法**：保持虚拟机配置精简稳定，勿修改可能引发 VMM 崩溃的非官方内核参数。

### 陷阱 3：VMware 共享文件夹（HGFS）沙盒权限拦截
- **现象**：通过 vmrun 访问 `/Volumes/VMware Shared Folders/Nemo` 编译时，抛出 `Operation not permitted` 或找不到头文件。
- **原因**：macOS TCC（Transparency, Consent, and Control）安全沙盒对非交互式后台会话（无 UI 登录的脚本上下文）限制了对外部挂载卷的读写。
- **解法**：在宿主机端将源码打包为 `tar.gz`，通过 `vmrun CopyFileFromHostToGuest` 注入虚拟机本地硬盘（如 `/Users/ajian/Desktop/NemoWorkspace`），本地读写性能提升 3~5 倍且完全免疫 TCC 权限问题。

### 陷阱 4：Windows 与 POSIX 路径反斜杠打包缺陷
- **现象**：Windows 打包的 zip 或 tar 在 macOS 下解压时，出现 `cannot find 'LearningHomeView' in scope`，文件全部被解压在同一平级目录。
- **原因**：Windows 默认反斜杠 `\` 在 POSIX 环境中会被视作普通字符而非目录分隔符，导致子目录结构扁平化丢失。
- **解法**：使用 Python 打包时，显式将路径替换为标准正斜杠 `/`：
  ```python
  rel_path = os.path.relpath(full_path, src_dir).replace('\\', '/')
  ```

### 陷阱 5：xcode-select 工具链指针漂移
- **现象**：`xcodebuild` 报错 `tool 'xcodebuild' requires Xcode, but active developer directory is a command line tools instance`。
- **原因**：macOS 默认激活了精简版 Command Line Tools，而非完整的 Xcode.app 开发者路径。
- **解法**：一次性修正指向：
  ```bash
  sudo xcode-select -s /Users/ajian/Desktop/Xcode.app/Contents/Developer
  ```

---

## 3. 自动化编译流水线实现

### 步骤 1：宿主机打包源码
排除 Git 历史与编译衍生文件，保留纯净源码结构并正斜杠化：
```python
import os, tarfile

src_dir = r'E:\Nemo\iOS\Nemo'
tar_path = os.path.expandvars(r'%TEMP%\Nemo_iOS.tar.gz')
if os.path.exists(tar_path):
    os.remove(tar_path)

with tarfile.open(tar_path, 'w:gz') as tar:
    for root, dirs, files in os.walk(src_dir):
        if '.agent' in root or '.build' in root or '.git' in root:
            continue
        for f in files:
            if f.startswith('._'):
                continue
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, src_dir).replace('\\', '/')
            tar.add(full_path, arcname=rel_path)
```

### 步骤 2：利用 vmrun CLI 传输并执行构建
```powershell
$vmrun = "D:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
$vmx   = "D:\macOS_VM\macOS_26\macOS_26.vmx"
$user  = "ajian"
$pass  = "666666"

# 1. 投递源码包至虚拟机 /tmp
& $vmrun -gu $user -gp $pass CopyFileFromHostToGuest $vmx "$env:TEMP\Nemo_iOS.tar.gz" "/tmp/Nemo_iOS.tar.gz"

# 2. 虚拟机内静默解压、编译、生成 Payload 并压缩成 IPA
& $vmrun -gu $user -gp $pass runProgramInGuest $vmx /bin/bash -c "
cd /Users/ajian/Desktop/NemoWorkspace
tar -xzf /tmp/Nemo_iOS.tar.gz
xcodebuild -project Nemo.xcodeproj \
  -scheme Nemo \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build
rm -rf /tmp/Payload /tmp/Nemo.ipa
mkdir -p /tmp/Payload
cp -R build/Build/Products/Release-iphoneos/Nemo.app /tmp/Payload/
cd /tmp && zip -r -y -q Nemo.ipa Payload
"

# 3. 拉取 IPA 回宿主机
& $vmrun -gu $user -gp $pass CopyFileFromGuestToHost $vmx "/tmp/Nemo.ipa" "E:\Nemo\Nemo.ipa"
```

---

## 4. Windows 端真机签名与部署指南

生成的 `E:\Nemo\Nemo.ipa` 是一个结构完整、但尚未绑定设备证书的纯净安装包。通过爱思助手进行合法签名直装：

1. **打开爱思助手**：
   - 确保 iPhone 已通过原装数据线或同局域网 Wi-Fi 与电脑连接，并在手机上点击了“信任此电脑”。
2. **进入签名工具**：
   - 顶部导航栏选择 **【工具箱】** ➔ 打开 **【IPA 签名】**。
3. **导入 IPA**：
   - 点击 **【添加 IPA】**，定位并选中 `E:\Nemo\Nemo.ipa`。
4. **选择签名模式**：
   - 勾选 **【使用 Apple ID 签名】**；
   - 点击“添加 Apple ID”，输入个人常用的 Apple ID 和密码（仅用于向苹果服务器申请 7 天个人免费证书，无任何风险）。
5. **开始签名与直装**：
   - 点击 **【开始签名】**，一般耗时 5~15 秒完成；
   - 签名成功后，点击列表右侧的 **【安装】**，爱思助手将把应用直接推送到 iPhone。
6. **手机端首次信任**：
   - 首次在手机屏幕上点击 Nemo 图标会提示“不受信任的开发者”；
   - 打开 iPhone **【设置】➔【通用】➔【VPN 与设备管理】**；
   - 在“开发者 App”下方点击你的 Apple ID，选择 **【信任】** 即可永久免越狱运行。

---

## 5. Swift / SwiftUI 跨平台与规范要点

在无 Mac 实体机的开发流程中，为确保代码能一次性在虚拟机中编译通过，需牢记以下规范：

1. **系统材质与 Apple HIG 液态玻璃（Liquid Glass）规范**：
   - 苹果官方禁用机械循环的 CSS 伪流光（扫光条纹）；
   - 正统玻璃质感：底层 `.ultraThinMaterial`（GPU 动态模糊）+ 半透明主题色浸润层 + 1px 镜面反射渐变边框（`strokeBorder`）+ 顶部曲面透镜微光；
   - 触碰交汇互动：按压时弹簧物理压缩（`interpolatingSpring`）+ 材质光学浓度受力加深 + 硬件 Taptic Engine（`UIImpactFeedbackGenerator(.medium)`）。
2. **跨平台语义色彩兼容**：
   - 在 Xcode 项目中，若使用了 `UIColor.systemGroupedBackground`，需做环境隔离，避免 macOS / Preview 编译阶段报色彩无推断错误：
     ```swift
     #if canImport(UIKit)
     public static let nemoGroupedBackground = Color(uiColor: .systemGroupedBackground)
     #else
     public static let nemoGroupedBackground = Color(nsColor: .windowBackgroundColor)
     #endif
     ```
3. **Gradient 参数类型严格区分**：
   - `LinearGradient` 接收的是 `startPoint` 与 `endPoint`（如 `.topLeading`、`.bottomTrailing`），切勿写错为 `startAngle` 与 `endAngle`（后者仅用于 `AngularGradient`）。

---

## 6. 一键全自动编译脚本

将下列脚本保存为 `E:\Nemo\build_ios.ps1`，后续在终端中仅需输入 `powershell E:\Nemo\build_ios.ps1` 即可全自动构建：

```powershell
# =====================================================================
# Nemo iOS 一键跨平台自动化构建流水线
# =====================================================================
$ErrorActionPreference = "Stop"

$SrcDir  = "E:\Nemo\iOS\Nemo"
$OutIpa  = "E:\Nemo\Nemo.ipa"
$Vmrun   = "D:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
$VmxPath = "D:\macOS_VM\macOS_26\macOS_26.vmx"
$VmUser  = "ajian"
$VmPass  = "666666"

Write-Host "[1/4] 正在打包宿主机源码 (统一 POSIX 路径)..." -ForegroundColor Cyan
python -c "
import os, tarfile
src = r'$SrcDir'
tar_p = os.path.expandvars(r'%TEMP%\Nemo_iOS.tar.gz')
if os.path.exists(tar_p): os.remove(tar_p)
with tarfile.open(tar_p, 'w:gz') as tar:
    for root, dirs, files in os.walk(src):
        if '.agent' in root or '.build' in root or '.git' in root: continue
        for f in files:
            if f.startswith('._'): continue
            fp = os.path.join(root, f)
            tar.add(fp, arcname=os.path.relpath(fp, src).replace('\\', '/'))
"

Write-Host "[2/4] 正在推送源码包至虚拟机..." -ForegroundColor Cyan
& $Vmrun -gu $VmUser -gp $VmPass CopyFileFromHostToGuest $VmxPath "$env:TEMP\Nemo_iOS.tar.gz" "/tmp/Nemo_iOS.tar.gz"

Write-Host "[3/4] 虚拟机正在执行 Release 无签名编译与 IPA 组装..." -ForegroundColor Cyan
& $Vmrun -gu $VmUser -gp $VmPass runProgramInGuest $VmxPath /bin/bash -c "
cd /Users/ajian/Desktop/NemoWorkspace
tar -xzf /tmp/Nemo_iOS.tar.gz
xcodebuild -project Nemo.xcodeproj -scheme Nemo -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO clean build
rm -rf /tmp/Payload /tmp/Nemo.ipa
mkdir -p /tmp/Payload
cp -R build/Build/Products/Release-iphoneos/Nemo.app /tmp/Payload/
cd /tmp && zip -r -y -q Nemo.ipa Payload
"

Write-Host "[4/4] 正在拉取生成的 IPA 产物到 Windows..." -ForegroundColor Cyan
& $Vmrun -gu $VmUser -gp $VmPass CopyFileFromGuestToHost $VmxPath "/tmp/Nemo.ipa" $OutIpa

$ipaItem = Get-Item $OutIpa
Write-Host "======================================================" -ForegroundColor Green
Write-Host "✅ 构建成功！" -ForegroundColor Green
Write-Host "产物文件：$($ipaItem.FullName)" -ForegroundColor Green
Write-Host "文件大小：$($ipaItem.Length) 字节" -ForegroundColor Green
Write-Host "导出时间：$($ipaItem.LastWriteTime)" -ForegroundColor Green
Write-Host "现在可打开【爱思助手】->【工具箱】->【IPA签名】直装 iPhone！" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
```
