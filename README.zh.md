<div align="right">

[English](./README.md) · **简体中文**

</div>

<div align="center">
  <img src="Bonfire/Resources/burning.png" width="120" alt="Bonfire icon">

# Bonfire

**一个迷你的 macOS 菜单栏 app —— 让你的 Mac 持续唤醒，合盖也不睡。**

为长时间无人值守的运行场景而做：Agent 循环、长 build、本地模型训练、大文件下载。

</div>

---

## 功能

- 🔥 **菜单栏一键切换** —— 30 分 / 1 小时 / 2 小时 / 4 小时 / 自定义时长 / 一直开
- 🌙 **保持唤醒的同时关屏** —— 点一下「Turn off display」，合盖走人
- 🔌 **合盖感知** —— 插电时合盖 Mac 继续跑
- 🔋 **电池模式** —— 高级开关（`pmset disablesleep`），让「合盖不睡」在电池下也能工作
- 🛡️ **电池安全护栏** —— 电量低于阈值（默认 20%）自动停止，防止无人值守跑空电池
- 🔐 **只弹一次密码框** —— 高级模式装一个微型 `sudoers` 片段，之后所有调用静默
- ⏱️ **聪明的定时** —— 「跑到 23:00」如果当天已经过了，自动滚到明天
- 💤 **优雅退出** —— 定时到、手动停止、或 app 崩溃，都会自动恢复正常 sleep 策略

## 安装

在 [Releases](../../releases) 页面下载最新的 `Bonfire.dmg`，双击挂载，把 Bonfire 拖到 Applications 快捷方式上。

**首次启动**：因为是 ad-hoc 签名（不是 Apple 公证版），macOS Gatekeeper 会拦截。两种解决方法：

- **右键 app → 打开 → 在弹窗里再点「打开」**，或
- 终端跑一次：
  ```bash
  xattr -dr com.apple.quarantine /Applications/Bonfire.app
  ```

只需要做一次，之后 macOS 记住了。

## 使用

点菜单栏上的篝火图标：

**定时保持唤醒** —— 点 `30m`、`1h`、`2h`、`4h`，或者展开 `Custom ▾` 输入任意时长。Bonfire 切到 burning 界面，显示实时倒计时。到时自动停止，Mac 恢复正常 sleep 策略。

**永久保持唤醒（直到你手动停止）** —— 点 `Keep awake`。完事后点 `Stop`。

**提前关屏**（让系统保持运行的同时） —— 在 burning 界面点 `Turn off display`。合盖走人之前用最合适。动鼠标或敲键盘就唤醒屏幕。

### Bonfire 激活时会发生什么

- 你的 Mac 全程保持唤醒，即使你不碰它。
- 屏幕可能还是会自己变暗或熄灭 —— 没事，Mac 在底下继续跑。
- **合盖时也保持运行 —— 但只在插电时**。在电池模式下，合盖仍然会让 Mac 睡眠，除非你开启下面的高级电池模式。
- 电池模式下，电量低于阈值（默认 20%）Bonfire 自动停止，避免无人值守把电跑空。
- 定时器在合盖、关屏、人不在的情况下都能继续走 —— 它跑在菜单栏 app 的进程里，跟 UI 完全解耦。

### 高级：电池模式（合盖 + 电池）

默认情况下，macOS 在电池模式下合盖会强制睡眠 —— 普通 app 无法绕过这个策略。Bonfire 提供一个可选的解法：

1. 打开 `Preferences…` → 开启 **Keep awake on battery with lid closed**。
2. 下次你在电池模式下启动 session 时，Bonfire 会**只在第一次**弹一次管理员密码框，安装一个小型 `sudoers` 片段。
3. 之后电池模式合盖唤醒就静默工作，永远不再弹密码 —— 跨 app 重启、跨系统重启都有效。

这个片段给 admin 组授予**精确的两条 pmset 命令**的免密 sudo 权限，仅此而已：

```
%admin ALL = (root) NOPASSWD: /usr/bin/pmset -b disablesleep 0, /usr/bin/pmset -b disablesleep 1
```

随时撤销：`sudo rm /etc/sudoers.d/bonfire-pmset`。

⚠️ 电池还是会消耗。低电量自动停止护栏仍然生效 —— 电量降到你设的阈值时 Bonfire 会自动停止。

## 工作原理

两层防睡叠加使用：

| 层 | 调用的 API | 效果 | 权限 |
|---|---|---|---|
| 系统空闲 / idle sleep | `IOPMAssertion`（`PreventUserIdleSystemSleep` + `PreventSystemSleep`） | 阻止系统因 idle 进入 sleep。**插电时**这层就够让合盖不睡 | 无需 |
| 电池下被强制的合盖 sleep | `pmset -b disablesleep 1`（通过免密 `sudo`） | 覆盖 macOS 在电池模式下「合盖 = 立刻睡」的硬性策略 | 管理员（一次性安装） |

熄屏功能用 `pmset displaysleepnow`（不需要管理员）。

设计细节和取舍权衡：[`docs/design.md`](docs/design.md)。

## 从源码 build

需要 Xcode 15+ 和 Homebrew。

```bash
brew install xcodegen
git clone https://github.com/<your-user>/bonfire.git
cd bonfire
xcodegen
open Bonfire.xcodeproj
```

或者直接打包：

```bash
./scripts/build.sh
# → dist/Bonfire.app, dist/Bonfire.zip, dist/Bonfire.dmg
```

跑全部测试：

```bash
xcodebuild -project Bonfire.xcodeproj -scheme Bonfire -destination 'platform=macOS' test
```

49 个单元测试，覆盖状态机、定时计算、配置持久化、IOKit 封装。

## 项目结构

```
Bonfire/
├── BonfireApp.swift                @main 入口
├── AppIcon.icns                    App 图标（用 scripts/make-icon.sh 重新生成）
├── Core/
│   ├── BonfireDomain.swift         状态枚举
│   ├── BonfireController.swift     状态机（mock 依赖、可单元测试）
│   ├── AssertionManager.swift      IOPMAssertion 封装
│   ├── PowerMonitor.swift          IOPS 电源事件
│   ├── Notifier.swift              UserNotifications 封装
│   ├── BatteryAwakeBypass.swift    pmset + sudoers 片段安装
│   └── DurationCalculator.swift    「Until」时间计算
├── Support/
│   ├── Preferences.swift           @AppStorage 持久化配置
│   ├── LaunchAtLogin.swift         SMAppService 封装
│   ├── IconRenderer.swift          菜单栏图标（PNG + fallback）
│   ├── Display.swift               pmset displaysleepnow
│   └── WindowAccessor.swift        SwiftUI ↔ NSWindow 桥
├── Views/
│   ├── PopoverView.swift           状态路由（idle / burning）
│   ├── IdleLayout.swift            预设 + 自定义 + forever
│   ├── BurningLayout.swift         倒计时 + 停止 + 熄屏
│   ├── PreferencesView.swift       设置窗口
│   └── InfoView.swift              「工作原理」窗口
└── Resources/
    ├── burning.png                 菜单栏图标（burning 态）
    └── idle.png                    菜单栏图标（idle 态）
```

架构上每个触碰 IOKit 的组件都隔在 protocol 后面，所以状态机的单元测试不需要真的让系统睡眠就能验证。

## 卸载

Bonfire 在 `/Applications` 之外的痕迹很少：

- `~/Library/Preferences/ai.dotwise.Bonfire.plist` —— 用户配置
- `/etc/sudoers.d/bonfire-pmset` —— **只有**你启用过「电池下合盖也唤醒」才会有。删除方式：
  ```bash
  sudo rm /etc/sudoers.d/bonfire-pmset
  ```
- `SMAppService` 登录项 —— 删除 app 时自动清理

## 已知限制

- **Ad-hoc 签名**，没走 Apple 公证。首次启动会有 Gatekeeper 警告，右键 → 打开就行。
- **电池 + 合盖模式** 会修改系统级 `pmset` 策略。如果 app 在使用中崩溃，下次启动会静默还原；如果你手动删了 sudoers 片段，跑一下 `sudo pmset -b disablesleep 0` 保险。
- **接外接显示器 + 合盖 + 不启用 bypass**：macOS 在插电时自己会进入「clamshell mode awake」—— 那个场景下 Bonfire 是冗余但无害。

## License

MIT 协议。见 [LICENSE](./LICENSE)。
