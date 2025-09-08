IP=$1
if [[ -z "${IP}" ]]; then
  IP=127.0.0.1
fi

GETH_URL=http://${IP}:8545

curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  ${GETH_URL} | jq .
