#!/bin/zsh
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/cal-plane-reminders"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
MEAL_LABEL="com.cal-plane-reminders.meal"
CALWATCH_LABEL="com.cal-plane-reminders.calwatch"
MEAL_PLIST="$LAUNCH_AGENTS_DIR/$MEAL_LABEL.plist"
CALWATCH_PLIST="$LAUNCH_AGENTS_DIR/$CALWATCH_LABEL.plist"
USER_ID="$(id -u)"

echo "正在卸载粉色小飞机·日历版……"

# 停掉并移除两个 launchd。
launchctl bootout "gui/$USER_ID" "$MEAL_PLIST" 2>/dev/null || true
launchctl bootout "gui/$USER_ID" "$CALWATCH_PLIST" 2>/dev/null || true
rm -f "$MEAL_PLIST" "$CALWATCH_PLIST"

# 兜底：杀掉可能还在跑的守护进程。
pkill -f "$INSTALL_DIR/cal-watcher" 2>/dev/null || true

# 删除安装目录（含编译产物、日志、去重文件）。
rm -rf "$INSTALL_DIR"

echo "卸载完成。日历访问权限如需彻底清除，可到 系统设置→隐私与安全性→日历 手动移除。"
