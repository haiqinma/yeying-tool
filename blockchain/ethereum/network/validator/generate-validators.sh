#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <start> <end>"
    exit 1
fi

START=$1
END=$2

# 导入通用配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source ${PARENT_DIR}/share/common.sh

EXPORT_DIR=$OUTPUT_DIR/config/key_${VALIDATOR_START_INDEX}_${VALIDATOR_END_INDEX}

MNEMONICS=$(get_node_mnemonics)

# 检查 MNEMONICS 和 PASSWORD 是否设置
if [ -z "$MNEMONICS" ]; then
    echo "Error: MNEMONICS is not set."
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "Error: PASSWORD is not set."
    exit 1
fi

log_info "Generating validator keys...\n"

eth2-val-tools keystores \
    --source-mnemonic "${MNEMONICS}" \
    --source-min ${START} \
    --source-max ${END} \
    --out-loc $EXPORT_DIR/keys \
    --prysm-pass "${PASSWORD}" \
    --insecure

log_info "Validator keys setup completed!"
