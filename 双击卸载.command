#!/bin/zsh
# 双击运行：切到本文件所在目录，执行卸载脚本。
cd "$(dirname "$0")"
chmod +x uninstall.sh 2>/dev/null
./uninstall.sh
echo ""
echo "（可以关闭此窗口了）"
