IP=$1
if [[ -z "${IP}" ]]; then
  IP=127.0.0.1
fi

BEACON_URL=http://${IP}:3500

echo "\n=====================开始检查共识节点=====================\n"

echo "\n01. 检查当前节点是否健康"
curl -s ${BEACON_URL}/eth/v1/node/health

echo "\n02，查看当前节点同步状态"
curl -s ${BEACON_URL}/eth/v1/node/syncing | jq .

echo "\n03，查看对等节点（peers）信息"
curl -s ${BEACON_URL}/eth/v1/node/peers | jq .

echo "\n05，查看当前节点的信息"
curl -s ${BEACON_URL}/eth/v1/node/identity | jq .

echo "\n06，查看当前节点版本信息"
curl -s ${BEACON_URL}/eth/v1/node/version | jq .

echo "\n07，获得信标链的创世信息"
curl -s "${BEACON_URL}/eth/v1/beacon/genesis" | jq .

echo "\n08. 获取当前节点最新区块信息"
curl -s ${BEACON_URL}/eth/v1/beacon/headers/head | jq .
# 结果描述：
# Slot：区块所在的插槽编号。
# Proposer Index：提出该区块的验证者索引。
# Parent Root：父区块的根哈希。
# State Root：区块状态的根哈希。
# Body Root：区块体的根哈希。
# Signature：区块的签名。

echo "\n09，查看所有验证者信息"
curl -s "${BEACON_URL}/eth/v1/beacon/states/head/validators" | jq .
# 结果描述：
# Index：验证者的索引。
# Balance：验证者的余额。
# Status：验证者的状态（例如，活跃、退出等）。
# Validator：验证者的详细信息，包括公钥、激活状态、退出状态等。

echo "\n10. 检查最终确定状态:"
curl -s ${BEACON_URL}/eth/v1/beacon/states/head/finality_checkpoints | jq .
# 结果描述：
# Previous Justified Checkpoint：上一个已被证明的检查点。
#   Epoch：对应的纪元。
#   Root：检查点的根哈希。
# Current Justified Checkpoint：当前被证明的检查点。
#   Epoch：对应的纪元。
#   Root：检查点的根哈希。
# Finalized Checkpoint：最终确定的检查点。
#   Epoch：对应的纪元。
#   Root：检查点的根哈希。

echo "\n=====================结束检查共识节点=====================\n"

