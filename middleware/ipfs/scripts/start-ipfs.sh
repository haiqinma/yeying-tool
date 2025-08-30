#!/bin/sh
set -e

echo "=== IPFS Startup Script ==="
echo "IPFS Path: $IPFS_PATH"
echo "IPFS Profile: $IPFS_PROFILE"

# 确保数据目录存在
mkdir -p /data/ipfs

# 初始化检查
if [ ! -f /data/ipfs/config ]; then
    echo "Initializing IPFS with profile: $IPFS_PROFILE"
    ipfs init --profile "$IPFS_PROFILE"
    echo "IPFS initialized successfully"
else
    echo "IPFS already initialized"
fi

# 配置 API 访问
echo "Configuring IPFS..."
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET", "DELETE"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type"]'

# 配置地址
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# 显示配置
echo "Current IPFS configuration:"
ipfs config show | head -20

echo "Starting IPFS daemon..."
exec ipfs daemon --migrate=true --enable-gc --routing=dhtclient

