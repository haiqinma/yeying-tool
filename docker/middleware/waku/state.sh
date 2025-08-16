
# 可用的restful api接口，查阅源代码cmd/waku/server/rest/目录
curl -s http://localhost:8646/health | jq .

curl -s http://localhost:8646/debug/v1/info | jq .

curl -s http://localhost:8646/debug/v1/version | jq .

curl -s http://localhost:8646/admin/v1/peers | jq .

curl -s http://localhost:8646/filter/v2/subscriptions | jq .

curl -s http://localhost:8646/store/v1/messages | jq .

curl -s http://localhost:8646/relay/v1/messages/myapp/1/chat/proto | jq .
