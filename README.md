# 粉色小飞机 · 日历版提醒

一个 macOS 桌面浮层动画：粉色小飞机从屏幕上方飞过，带一句提醒文字。

## 功能

- **每天**（含周末）**12:00** 提醒吃午饭、**17:45** 提醒吃晚饭
- 自动扫描苹果日历 App 里**全部日历**，任意日程**开始前 5 分钟**弹飞机提醒（忽略全天日程）
- 动画约 10 秒，飞完自动消失，不常驻打扰

## 系统要求

- macOS（Intel 或 Apple Silicon 均可，如 MacBook Air M 系列）
- 需要 `swiftc` 编译环境（装过 Xcode 或命令行工具即有）。若缺失，安装时会提示先运行：
  ```bash
  xcode-select --install
  ```

## 安装（打开即用）

1. 打开 `cal-plane-reminders` 文件夹
2. 双击 **`双击安装.command`**
3. 若 macOS 拦截：系统设置 → 隐私与安全性 → 「仍要打开」
4. 首次会弹**日历访问权限**授权框 → 点【允许】
5. 看到「安装完成」即可关闭窗口

## 修改吃饭时间

编辑本包里的 `install.sh`，改顶部这两行（24 小时制，4 位数字 HHMM）：

```bash
LUNCH_HHMM="1200"    # 午饭
DINNER_HHMM="1745"   # 晚饭
```

保存后**重新双击「双击安装.command」**即可生效。

## 手动预览飞机

```bash
~/.local/share/cal-plane-reminders/plane "测试一下" 🛩
```

## 日历权限没生效怎么办

日历守护第一次跑会申请权限。如果没弹授权框、或误点了拒绝：

> 系统设置 → 隐私与安全性 → 日历 → 打开对应项（终端 / cal-watcher）

然后双击卸载再重装一次。

## 卸载

双击 **`双击卸载.command`**（会移除定时任务、守护进程和安装文件）。

## 安装位置

```text
~/.local/share/cal-plane-reminders/        # 编译产物、日志、去重文件
~/Library/LaunchAgents/com.cal-plane-reminders.meal.plist       # 吃饭定时
~/Library/LaunchAgents/com.cal-plane-reminders.calwatch.plist   # 日历守护
```

## 隐私说明

全部在本机编译运行，读日历用系统 EventKit，**不联网、不上传任何数据**。
