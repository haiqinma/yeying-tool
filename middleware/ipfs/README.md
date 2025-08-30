


# 使用 POST 请求版本
curl -s -X POST http://localhost:5001/api/v0/version | jq .

# 或者测试 ID
curl -s -X POST http://localhost:5001/api/v0/id | jq .

# 测试节点状态
curl -s -X POST http://localhost:5001/api/v0/swarm/peers | jq .

# 测试上传文件
echo "Hello IPFS" | curl -X POST -F file=@- http://localhost:5001/api/v0/add
