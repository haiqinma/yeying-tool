#!/bin/bash
# 使用 API 创建检查点

IP=$1
if [[ -z "${IP}" ]]; then
  IP=127.0.0.1
fi

BEACON_URL=http://${IP}:3500

CHECKPOINT_DIR="./checkpoints"
mkdir -p "$CHECKPOINT_DIR"

# 获取当前 slot 和状态根
HEAD_INFO=$(curl -s $BEACON_URL/eth/v1/beacon/headers/head)
SLOT=$(echo "$HEAD_INFO" | jq -r '.data.header.message.slot')
STATE_ROOT=$(echo "$HEAD_INFO" | jq -r '.data.header.message.state_root')

echo "创建 slot $SLOT 的检查点，状态根: $STATE_ROOT"

# 创建检查点目录
CHECKPOINT_PATH="$CHECKPOINT_DIR/$SLOT"
mkdir -p "$CHECKPOINT_PATH"

# 获取状态 SSZ
curl -s -X GET -H "Accept: application/octet-stream" "$BEACON_URL/eth/v2/debug/beacon/states/$STATE_ROOT" \
  --output "$CHECKPOINT_PATH/state.ssz"

echo "检查点已创建: $CHECKPOINT_PATH/state.ssz"

