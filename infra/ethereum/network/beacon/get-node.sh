IP=$1
if [[ -z "${IP}" ]]; then
  IP=127.0.0.1
fi

BEACON_URL=http://${IP}:3500

echo "\n01. 检查当前节点是否健康"
curl -s ${BEACON_URL}/eth/v1/node/health

echo "\n02，查看当前节点同步状态"
curl -s ${BEACON_URL}/eth/v1/node/syncing | jq .

echo "\n05，查看当前节点的信息"
curl -s ${BEACON_URL}/eth/v1/node/identity | jq .

echo "\n06，查看当前节点版本信息"
curl -s ${BEACON_URL}/eth/v1/node/version | jq .

