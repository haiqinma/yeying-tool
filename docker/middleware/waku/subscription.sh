CURL=http://localhost:8646
curl -X POST "${CURL}/relay/v1/subscriptions" \
  -H "Content-Type: application/json" \
  -d '["/waku/2/rs/5432/0"]'
