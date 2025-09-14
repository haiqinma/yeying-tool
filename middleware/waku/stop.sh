#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 从env文件加载配置
if [ -f .env ]; then
    source ${SCRIPT_DIR}/.env
fi

PID_FILE="waku.pid"

# 检查是否需要重新启动
if [ ! -f "$PID_FILE" ]; then
  echo "There is no pid file."
  exit 0
fi

OLD_PID=$(cat "$PID_FILE")
echo "Killing existing process with PID: $OLD_PID"
kill "$OLD_PID"
rm "$PID_FILE"
