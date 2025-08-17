#!/bin/bash

# 基础配置
SOURCE_BASE="/data/devnet"
TARGET_BASE="/data/devnet"
USER="root"

# 目标服务器数组 - 添加更多IP只需在此处添加
TARGETS=(
  # 可以添加更多目标服务器，例如:
)

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

  # 可以添加更多文件，例如:
  # "config/custom.txt:config/custom.txt"
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

  scp "$source" "${USER}@${target_host}:${target}" > /dev/null 2>&1

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
      full_source="${SOURCE_BASE}/${source_path}"
      full_target="${TARGET_BASE}/${target_path}"

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
