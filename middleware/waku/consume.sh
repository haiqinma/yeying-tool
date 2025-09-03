#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 从env文件加载配置
if [ -f .env ]; then
    source ${SCRIPT_DIR}/.env
fi

WAKU_URL=${WAKU_URL:-http://127.0.0.1:8646}
CLUSTER_ID=${CLUSTER_ID:-3302}
PUBSUB_TOPIC=/waku/2/rs/${CLUSTER_ID}/0


ENCODED_TOPIC=$(echo -n "$PUBSUB_TOPIC" | jq -sRr @uri)

while true; do
  RESP=$(curl -s -X GET "${WAKU_URL}/relay/v1/messages/${ENCODED_TOPIC}")
  # 检查 RESP 是否为有效的 JSON 数组
  if [[ -z "$RESP" || "$RESP" == "null" ]]; then
    echo "无消息"
    sleep 5
    continue
  fi
  
  if [[ ! "$RESP" =~ ^\[ ]]; then
    echo "返回内容不是数组，内容如下："
    echo "$RESP"
    sleep 5
    continue
  fi
  
  COUNT=$(echo "$RESP" | jq 'length')
  if [[ "$COUNT" -eq 0 ]]; then
    echo "无消息"
    sleep 5
    continue
  fi

  echo "$RESP" | jq -c '.[]' | while read -r ITEM; do
    PAYLOAD=$(echo "$ITEM" | jq -r '.payload')
    TOPIC=$(echo "$ITEM" | jq -r '.contentTopic')
    TS=$(echo "$ITEM" | jq -r '.timestamp')
    # 时间戳转为可读时间
    TIME=$(date -d "@$TS" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$TS")
    echo "Topic: $TOPIC"
    echo "时间戳: $TS ($TIME)"
    echo "原始 payload: $PAYLOAD"
    echo -n "解码后内容: "
    echo "$PAYLOAD" | base64 -d
    echo
  done
  sleep 5
done
