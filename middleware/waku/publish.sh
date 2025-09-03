#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 从env文件加载配置
if [ -f .env ]; then
    source ${SCRIPT_DIR}/.env
fi

WAKU_URL=${WAKU_URL:-http://127.0.0.1:8646}
CLUSTER_ID=${CLUSTER_ID:-3302}
PUBSUB_TOPIC=/waku/2/rs/${CLUSTER_ID}/0

TIMESTAMP=$(date +%s)
MESSAGE=$1

PAYLOAD=$(echo -n "$MESSAGE" | base64)
ENCODED_TOPIC=$(echo "$PUBSUB_TOPIC" | jq -sRr @uri)

curl -X POST "${WAKU_URL}/relay/v1/messages/${ENCODED_TOPIC}" -H "Content-Type: application/json" -d "{\"contentTopic\":\"test\",\"payload\":\"${PAYLOAD}\",\"timestamp\": ${TIMESTAMP}}"
