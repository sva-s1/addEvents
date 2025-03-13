#!/usr/bin/env zsh

ADD_EVENTS_API_URL="https://xdr.us1.sentinelone.net/api/addEvents"

# Check if .env file exists
if [ ! -f .env ]; then
  echo "Error: .env file not found"
  exit 1
fi

# Load .env variables
source .env

# Determine if SDL_LOG_ACCESS_WRITE_KEY is a 1Password reference or a direct key
if [[ "$SDL_LOG_ACCESS_WRITE_KEY" == op://* ]]; then
  echo && echo "🔐 Using 1Password integration to retrieve token..."
  TOKEN=$(op read "$SDL_LOG_ACCESS_WRITE_KEY")

  # Ensure token retrieval was successful
  if [ -z "$TOKEN" ]; then
    echo "❌ Error: Failed to retrieve SDL_LOG_ACCESS_WRITE_KEY from 1Password"
    exit 1
  fi
else
  echo && echo "🔑 Using direct API key from .env"
  TOKEN="$SDL_LOG_ACCESS_WRITE_KEY"
fi

# Use the provided API URL (geo-based reference in README)
URL=$ADD_EVENTS_API_URL

# Generate a nanosecond-precision timestamp
TS=$(($(date +%s)*1000000000))

# Generate a random UUID for the session ID
SESSION_ID=$(uuidgen)

# Generate random values
THREAD=$((RANDOM % 10 + 1))  # Random thread between 1-10
SEV=$((RANDOM % 4 + 1))      # Random severity between 1-4
RECORD_ID=$((RANDOM % 50000 + 10000)) # Random record ID between 10000-60000
LATENCY=$(awk -v min=5 -v max=50 'BEGIN{srand(); print min+rand()*(max-min)}')  # Random float latency between 5-50
LENGTH=$((RANDOM % 10000 + 10000))  # Random length between 10000-20000

# Common web messages (Zsh requires proper array indexing)
MESSAGES=("Request received" "Response sent" "Record retrieved" "Connection established" "Session terminated")
MESSAGE=${MESSAGES[RANDOM % ${#MESSAGES} + 1]} # Zsh 1-based index

echo "📢 Selected Message: $MESSAGE" && echo

# Construct JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "session": "$SESSION_ID",
  "events": [
    {
      "thread": "$THREAD",
      "ts": "$TS",
      "attrs": {
        "message": "$MESSAGE",
        "dataSource.category": "security",
        "dataSource.name": "API-Test",
        "dataSource.vendor": "SentinelOne",
        "recordId": $RECORD_ID,
        "latency": $LATENCY,
        "length": $LENGTH,
        "severity": $SEV,
        "dataset": "agentless-addEvents"
      }
    }
  ]
}
EOF
)

# Send the request
curl -X POST $URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$JSON_PAYLOAD"

echo