#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 从env文件加载配置
if [ -f .env ]; then
    source ${SCRIPT_DIR}/.env
fi

WAKU_URL=${WAKU_URL:-http://127.0.0.1:8646}

# 可用的restful api接口，查阅源代码cmd/waku/server/rest/目录
curl -s ${WAKU_URL}/health | jq .

curl -s ${WAKU_URL}/debug/v1/info | jq .

curl -s ${WAKU_URL}/debug/v1/version | jq .

curl -s ${WAKU_URL}/admin/v1/peers | jq .

curl -s ${WAKU_URL}/filter/v2/subscriptions | jq .

curl -s ${WAKU_URL}/store/v1/messages | jq .

curl -s ${WAKU_URL}/relay/v1/messages/myapp/1/chat/proto | jq .
