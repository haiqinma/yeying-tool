IP=$1
if [[ -z "${IP}" ]]; then
  IP=127.0.0.1
fi

GETH_URL=http://${IP}:8545

echo "\n=====================开始检查执行节点=====================\n"
echo "\n1. 检查执行层区块状态:"
curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
     ${GETH_URL} | jq .

echo "\n2. 检查最新区块详情:"
curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' \
      ${GETH_URL} | jq .


echo "\n3. 检查创世区块:"
curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0",false],"id":1}' \
      ${GETH_URL} | jq .

echo "\n4. 检查同步状态:"
curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
      ${GETH_URL} | jq .

echo "\n5. 检查peer连接:"
curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
      ${GETH_URL} | jq .

echo "\n=====================结束检查执行节点=====================\n"
