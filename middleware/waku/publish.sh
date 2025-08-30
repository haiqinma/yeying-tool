TOPIC=/waku/2/rs/5432/0
CURL=http://127.0.0.1:8646
TIMESTAMP=$(date +%s)
MESSAGE=$1

PAYLOAD=$(echo -n "$MESSAGE" | base64)
ENCODED_TOPIC=$(echo "$TOPIC" | jq -sRr @uri)

curl -X POST "${CURL}/relay/v1/messages/${ENCODED_TOPIC}" -H "Content-Type: application/json" -d "{\"contentTopic\":\"test\",\"payload\":\"${PAYLOAD}\",\"timestamp\": ${TIMESTAMP}}"
