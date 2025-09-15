IP=$1
if [[ -z "${IP}" ]]; then
  IP=127.0.0.1
fi

BEACON_URL=http://${IP}:3500

# 查看所有peers
curl -s -X GET "${BEACON_URL}/eth/v1/node/peers" | jq

# 查看连接的peers数量
curl -s -X GET "${BEACON_URL}/eth/v1/node/peers" | jq '.data | length'

# 查看peer详细信息
curl -s -X GET "${BEACON_URL}/eth/v1/node/peers" | jq '.data[] | {peer_id, state, direction, last_seen_p2p_address}'
