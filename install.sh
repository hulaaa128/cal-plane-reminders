#!/bin/zsh
set -euo pipefail

# ============================================================
#  可手动修改的吃饭提醒时间（24 小时制，4 位数字 HHMM）
#  改完保存，重新双击「双击安装.command」即可生效。
# ============================================================
LUNCH_HHMM="1200"    # 午饭提醒时间，默认 12:00
DINNER_HHMM="1745"   # 晚饭提醒时间，默认 17:45

LUNCH_MSG="皇帝，该吃午饭了"
LUNCH_EMOJI="🍱"
DINNER_MSG="皇帝，该吃晚饭了"
DINNER_EMOJI="🍚"
# ============================================================

PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/share/cal-plane-reminders"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
MEAL_LABEL="com.cal-plane-reminders.meal"
CALWATCH_LABEL="com.cal-plane-reminders.calwatch"
MEAL_PLIST="$LAUNCH_AGENTS_DIR/$MEAL_LABEL.plist"
CALWATCH_PLIST="$LAUNCH_AGENTS_DIR/$CALWATCH_LABEL.plist"
USER_ID="$(id -u)"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少命令：$1"
    echo "请先安装 Xcode Command Line Tools：xcode-select --install"
    echo "装好后重新双击本安装脚本即可。"
    exit 1
  fi
}

# 把 HHMM 拆成 Hour / Minute（去掉前导 0，避免被当八进制）。
hh_of() { echo $((10#${1:0:2})); }
mm_of() { echo $((10#${1:2:2})); }

write_meal_plist() {
  local lh lm dh dm
  lh="$(hh_of "$LUNCH_HHMM")"; lm="$(mm_of "$LUNCH_HHMM")"
  dh="$(hh_of "$DINNER_HHMM")"; dm="$(mm_of "$DINNER_HHMM")"
  cat > "$MEAL_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$MEAL_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/run_meal.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <array>
        <dict><key>Hour</key><integer>$lh</integer><key>Minute</key><integer>$lm</integer></dict>
        <dict><key>Hour</key><integer>$dh</integer><key>Minute</key><integer>$dm</integer></dict>
    </array>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/meal.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/meal.err</string>
</dict>
</plist>
PLIST
}

# run_meal.sh：launchd 到点后调用，按当前时刻判断午饭/晚饭。
write_run_meal() {
  cat > "$INSTALL_DIR/run_meal.sh" <<SCRIPT
#!/bin/zsh
set -euo pipefail
PLANE="$INSTALL_DIR/plane"
NOW="\$(date +%H%M)"
if [[ "\$NOW" == "$LUNCH_HHMM" ]]; then
  exec "\$PLANE" "$LUNCH_MSG" "$LUNCH_EMOJI"
fi
if [[ "\$NOW" == "$DINNER_HHMM" ]]; then
  exec "\$PLANE" "$DINNER_MSG" "$DINNER_EMOJI"
fi
# 时间对不上（极少数 launchd 抖动）不弹飞机。
exit 0
SCRIPT
  chmod +x "$INSTALL_DIR/run_meal.sh"
}

write_calwatch_plist() {
  cat > "$CALWATCH_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$CALWATCH_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/cal-watcher</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/calwatch.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/calwatch.err</string>
</dict>
</plist>
PLIST
}

load_agent() {
  local label="$1"
  local plist="$2"
  launchctl bootout "gui/$USER_ID" "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$USER_ID" "$plist"
  launchctl print "gui/$USER_ID/$label" >/dev/null
}

echo "开始安装粉色小飞机·日历版……"
require_command launchctl
require_command swiftc
mkdir -p "$INSTALL_DIR" "$LAUNCH_AGENTS_DIR"

# 在本机现场编译，自动适配当前架构（Intel / Apple Silicon 均可）。
echo "正在编译飞机浮层……"
swiftc "$PACKAGE_DIR/src/plane.swift" -o "$INSTALL_DIR/plane" -framework Cocoa
echo "正在编译日历守护……"
swiftc "$PACKAGE_DIR/src/cal_watcher.swift" -o "$INSTALL_DIR/cal-watcher" -framework EventKit -framework Foundation
chmod +x "$INSTALL_DIR/plane" "$INSTALL_DIR/cal-watcher"

# fired.txt 去重文件（首次创建空文件）。
[[ -f "$INSTALL_DIR/fired.txt" ]] || : > "$INSTALL_DIR/fired.txt"

write_run_meal
write_meal_plist
write_calwatch_plist
plutil -lint "$MEAL_PLIST" >/dev/null
plutil -lint "$CALWATCH_PLIST" >/dev/null

load_agent "$MEAL_LABEL" "$MEAL_PLIST"
load_agent "$CALWATCH_LABEL" "$CALWATCH_PLIST"

cat <<MSG

======== 安装完成 ========

自动提醒已开启（每天，含周末）：
- 午饭：$LUNCH_HHMM  →  粉色飞机「$LUNCH_MSG」
- 晚饭：$DINNER_HHMM  →  粉色飞机「$DINNER_MSG」
- 日历：任意日程开始前 5 分钟  →  粉色飞机提醒（忽略全天日程）

⚠️ 首次运行日历守护会弹「日历访问权限」授权框，请点【允许】。
   若没弹或误点拒绝：系统设置 → 隐私与安全性 → 日历，手动开启对应项。

手动预览飞机：
  $INSTALL_DIR/plane "测试一下" 🛩

想改吃饭时间：编辑本包里的 install.sh 顶部 LUNCH_HHMM / DINNER_HHMM，再双击安装一次。

卸载：双击「双击卸载.command」。
MSG
