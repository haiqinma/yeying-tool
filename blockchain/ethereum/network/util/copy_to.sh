#!/bin/bash

# 导入通用配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source ${PARENT_DIR}/share/common.sh

# 基础配置
SOURCE_BASE=${OUTPUT_DIR}
TARGET_BASE=${OUTPUT_DIR}
USER="root"

# 解析成数组
IFS=',' read -ra TARGETS <<< "$COPY_ADDRESS"

# 文件映射数组 - 格式: "源文件路径:目标文件路径"
# 源路径和目标路径都是相对于BASE_DIR的
FILES=(
  # 配置文件
  "config/beacon_enr.txt:config/beacon_enr.txt"
  "config/enode.txt:config/enode.txt"

  # 执行层文件
  "data/execution/genesis.json:data/execution/genesis.json"

  # 共识层文件
  "data/consensus/genesis.ssz:data/consensus/genesis.ssz"
  "data/consensus/config.yaml:data/consensus/config.yaml"

  # keys目录
  "config/key_${VALIDATOR_START_INDEX}_${VALIDATOR_END_INDEX}/keys:data/validator"
)

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的标题
print_section() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

# 复制文件函数
copy_file() {
  local source="$1"
  local target="$2"
  local target_host="$3"

  echo -n "复制 $(basename "$source") 到 $target_host... "

  scp -r "$source" "${USER}@${target_host}:${target}" > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}成功${NC}"
    return 0
  else
    echo -e "${RED}失败${NC}"
    return 1
  fi
}

# 确保目标目录存在
ensure_dir() {
  local dir="$1"
  local target_host="$2"

  ssh "${USER}@${target_host}" "mkdir -p $dir" > /dev/null 2>&1
}

# 主函数
main() {
  print_section "开始文件复制"

  # 统计
  local total_files=$((${#FILES[@]} * ${#TARGETS[@]}))
  local success_count=0
  local fail_count=0

  # 遍历所有目标服务器
  for target_host in "${TARGETS[@]}"; do
    print_section "复制到服务器: $target_host"
    # 遍历所有文件
    for file_mapping in "${FILES[@]}"; do
      # 分割源路径和目标路径
      IFS=':' read -r source_path target_path <<< "$file_mapping"

      # 构建完整路径
      if [[ "$source_path" == /* ]]; then
        full_source="${source_path}"
      else
        full_source="${SOURCE_BASE}/${source_path}"
      fi

      if [[ "$target_path" == /* ]]; then
        full_target="${target_path}"
      else
        full_target="${TARGET_BASE}/${target_path}"
      fi

      # 确保目标目录存在
      target_dir=$(dirname "$full_target")
      ensure_dir "$target_dir" "$target_host"

      # 复制文件
      if copy_file "$full_source" "$full_target" "$target_host"; then
        ((success_count++))
      else
        ((fail_count++))
      fi
    done
  done

  # 打印总结
  print_section "复制完成"
  echo -e "总计: $total_files 个文件"
  echo -e "${GREEN}成功: $success_count${NC}"
  if [ $fail_count -gt 0 ]; then
    echo -e "${RED}失败: $fail_count${NC}"
    exit 1
  fi
}

# 执行主函数
main
