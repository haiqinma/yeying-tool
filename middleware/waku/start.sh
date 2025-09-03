#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 从env文件加载配置
if [ -f .env ]; then
    source ${SCRIPT_DIR}/.env
fi

CLUSTER_ID=${CLUSTER_ID:-3302}
PUBSUB_TOPIC=/waku/2/rs/${CLUSTER_ID}/0
BOOTNODE=${BOOTNODE}
NAT_IP=${NAT_IP}

# 定义变量
WAKU_EXEC="./build/waku"
LOG_FILE="logs/waku.log"
PID_FILE="waku.pid"
FORCE_RESTART=false

# 解析参数
while getopts "f" opt; do
  case $opt in
    f)
      FORCE_RESTART=true
      ;;
    *)
      echo "Usage: $0 [-f]"
      exit 1
      ;;
  esac
done

# 检查是否需要重新启动
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if [ "$FORCE_RESTART" = true ]; then
    echo "Killing existing process with PID: $OLD_PID"
    kill "$OLD_PID"
    rm "$PID_FILE"
  else
    echo "Process is already running with PID: $OLD_PID"
    exit 0
  fi
fi

STATIC_NODE=""
if [ -z ${BOOTNODE} ];  then
   STATIC_NODE="--staticnode=${BOOTNODE}"
fi

# 启动新的进程
$WAKU_EXEC \
  --log-encoding=nocolor \
  --log-output=file:$LOG_FILE \
  --log-level=INFO \
  --cluster-id=$CLUSTER_ID \
  --peer-store-capacity=10 \
  --persist-peers \
  --key-file=./nodekey \
  --port=60000 \
  --host=0.0.0.0 \
  --rest \
  --rest-port=8646 \
  --rest-address=0.0.0.0 \
  --rest-admin \
  ${STATIC_NODE} \
  --relay \
  --store \
  --filter \
  --lightpush \
  --pubsub-topic=$PUBSUB_TOPIC \
  --ext-ip=$NAT_IP &

# 获取新进程的 PID
NEW_PID=$!

# 确保进程成功启动
sleep 2
if ps -p $NEW_PID > /dev/null; then
  echo $NEW_PID > "$PID_FILE"
  echo "Started new process with PID: $NEW_PID"
else
  echo "Failed to start process."
fi
