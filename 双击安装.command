#!/bin/zsh
# 双击运行：切到本文件所在目录，执行安装脚本。
cd "$(dirname "$0")"
chmod +x install.sh uninstall.sh 2>/dev/null
./install.sh
echo ""
echo "（可以关闭此窗口了）"
