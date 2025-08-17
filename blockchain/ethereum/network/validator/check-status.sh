#!/bin/bash

# 导入通用配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source ${PARENT_DIR}/share/common.sh

echo "\n=====================开始检查验证节点=====================\n"

MNEMONICS=$(get_node_mnemonics)

# 验证密钥导入
validator accounts list \
    --wallet-password-file $OUTPUT_DIR/config/password.txt \
    --wallet-dir $OUTPUT_DIR/data/validator/keys/prysm \
    --accept-terms-of-use

echo "\n=====================结束检查验证节点=====================\n"
