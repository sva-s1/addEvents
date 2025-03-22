#!/bin/bash
# Title: Agentless Testing Approach for Non-Production (POC) to Send Data to SentinelOne's Singularity Data Lake

# Greeting the user with a title
echo "Agentless Testing Approach for Non-Production (POC) to Send Data to SentinelOne's Singularity Data Lake"

# --------------------
# Function: select_url
# Purpose : Presents user with possible ingestion URLs and sets the chosen one
# --------------------
select_url() {
    echo "Choose SentinelOne Singularity Data Lake base ingest URL:"
    echo "1) https://xdr.us1.sentinelone.net (default)"
    echo "2) https://xdr.ca1.sentinelone.net"
    echo "3) https://xdr.eu1.sentinelone.net"
    echo "4) https://xdr.ap1.sentinelone.net"
    echo "5) https://xdr.aps1.sentinelone.net"
    echo "6) https://xdr.apse2.sentinelone.net"
    echo "For more info: https://community.sentinelone.com/s/article/000004961"
    echo
    read -p "Enter your choice (1-6) [1]: " choice
    case ${choice:-1} in
        1) BASE_URL="https://xdr.us1.sentinelone.net" ;;
        2) BASE_URL="https://xdr.ca1.sentinelone.net" ;;
        3) BASE_URL="https://xdr.eu1.sentinelone.net" ;;
        4) BASE_URL="https://xdr.ap1.sentinelone.net" ;;
        5) BASE_URL="https://xdr.aps1.sentinelone.net" ;;
        6) BASE_URL="https://xdr.apse2.sentinelone.net" ;;
        *) BASE_URL="https://xdr.us1.sentinelone.net" ;;
    esac
    URL="${BASE_URL}/api/addEvents"
    echo "Selected URL: $URL"
    echo
}

# -----------------------
# Function: select_event_type
# Purpose : Lets user choose sample event type (RFC 3164 or RFC 5424)
# -----------------------
select_event_type() {
    echo "Which log event sample would you like to send?"
    echo "1) Syslog RFC 3164 (default)"
    echo "2) Syslog RFC 5424 (NIST SP 800-53 preferred)"
    read -p "Enter your choice (1-2) [1]: " event_choice
    EVENT_CHOICE=${event_choice:-1}
    echo
}

# --------------------
# Main Script Begins
# --------------------

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Load .env variables
source .env

# Handle token retrieval
if [[ "$SDL_LOG_ACCESS_WRITE_KEY" == op://* ]]; then
    echo "Using 1Password integration to retrieve token..."
    if ! command -v op >/dev/null 2>&1; then
        echo "Error: 1Password CLI 'op' not found"
        exit 1
    fi
    TOKEN=$(op read "$SDL_LOG_ACCESS_WRITE_KEY")
    if [ -z "$TOKEN" ]; then
        echo "Error: Failed to retrieve SDL_LOG_ACCESS_WRITE_KEY from 1Password"
        exit 1
    fi
else
    echo "Using direct API key from .env"
    TOKEN="$SDL_LOG_ACCESS_WRITE_KEY"
fi

# Get URL choice
select_url

# Informational message about compliance
echo "Both Syslog RFC 3164 and RFC 5424 satisfy the logging requirements of most compliance frameworks"
echo "(e.g., PCI DSS, HIPAA, SOC 2, ISO 27001). However, NIST SP 800-53 prefers the newer RFC 5424 standard."
echo

# Get event type choice
select_event_type

# Generate random values
SESSION_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid || echo "$(date +%s)-$RANDOM-session")
SEARCH_TAG=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid || echo "$(date +%s)-$RANDOM-search")
THREAD=$((RANDOM % 10 + 1))
SEV=$((RANDOM % 6 + 1))

# We will pick a Transformers-themed serverId (the "serverId" is the main random hostname)
# Then, for RFC3164, we will override the syslog "hostname" in the message with either "teletraan1" (Autobot) or "nemesis" (Decepticon)
AUTOBOTS=("optimusprime" "bumblebee")
DECEPTICONS=("megatron" "starscream" "soundwave")
ALL_HOSTNAMES=("${AUTOBOTS[@]}" "${DECEPTICONS[@]}")

# Select a random serverId
HOSTNAME=${ALL_HOSTNAMES[$((RANDOM % ${#ALL_HOSTNAMES[@]}))]}

# Decide if it's an Autobot or Decepticon, set the RFC3164 message "hostname" theme
if [[ " ${AUTOBOTS[@]} " =~ " ${HOSTNAME} " ]]; then
    FACTION_HOSTNAME="teletraan1"
else
    FACTION_HOSTNAME="nemesis"
fi

# Sample messages
RFC3164_MESSAGES=("Authentication failed for user" "PAM authentication error" "Invalid login attempt")
RFC5424_MESSAGES=("Mount operation failed" "Filesystem check completed" "Partition resize successful")
APPLICATIONS=("CybertronAuth" "MatrixMonitor" "EnergonSync" "AutobotFirewall" "DecepticonScanner")

# Extra phrases to add a bit more randomness for RFC5424 message
EXTRA_PHRASES=("AllSpark scan" "StasisLock event" "Energon detection" "NeuralNetwork glitch" "Matrix infiltration")

# Select random items
if [ "$EVENT_CHOICE" = "1" ]; then
    MESSAGE="${RFC3164_MESSAGES[$((RANDOM % ${#RFC3164_MESSAGES[@]}))]}"
else
    MESSAGE="${RFC5424_MESSAGES[$((RANDOM % ${#RFC5424_MESSAGES[@]}))]}"
fi
APP=${APPLICATIONS[$((RANDOM % ${#APPLICATIONS[@]}))]}
RANDOM_PHRASE=${EXTRA_PHRASES[$((RANDOM % ${#EXTRA_PHRASES[@]}))]}
MESSAGE_FINAL="$MESSAGE - $RANDOM_PHRASE"

echo "Randomized values:"
echo "Session ID: $SESSION_ID"
echo "Search Tag: $SEARCH_TAG"
echo "Thread: $THREAD"
echo "Severity: $SEV"
echo "ServerId (Transformer Name): $HOSTNAME"
if [ "$EVENT_CHOICE" = "1" ]; then
    echo "RFC3164 chosen, hostname in message will be: $FACTION_HOSTNAME"
    echo "Message: $MESSAGE"
else
    echo "RFC5424 chosen"
    echo "Message: $MESSAGE"
    echo "Application: $APP"
    echo "Additional random phrase: $RANDOM_PHRASE"
fi
echo

# Generate timestamps
NOW=$(date +%s)
SDL_TS=$((NOW * 1000000000))

# --------------------
# Construct & Send Payload
# --------------------
if [ "$EVENT_CHOICE" = "1" ]; then
    # Syslog RFC 3164
    RFC3164_TS=$(date -u -r "$NOW" '+%b %d %H:%M:%S' 2>/dev/null || date -u -d "@$NOW" '+%b %d %H:%M:%S')

    # Build the syslog message with faction-based hostname
    MSG_SENT="<34> $RFC3164_TS $FACTION_HOSTNAME su: '$MESSAGE' for $FACTION_HOSTNAME on /dev/pts/8"

    # Escape double quotes for valid JSON
    ESCAPED_MSG_SENT=$(echo "$MSG_SENT" | sed 's/"/\\"/g')

    RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$(cat <<EOF
{
    "session": "$SESSION_ID",
    "sessionInfo": {
      "serverType": "syslog",
      "serverId": "$HOSTNAME"
    },
    "events": [
      {
        "thread": "$THREAD",
        "ts": "$SDL_TS",
        "sev": $SEV,
        "attrs": {
          "message": "$ESCAPED_MSG_SENT",
          "parser": "syslog",
          "dataset": "syslog_rfc_3164",
          "search_tag": "$SEARCH_TAG"
        }
      }
    ],
    "threads": [
      {"id": "$THREAD", "name": "syslog handler thread"}
    ]
}
EOF
)")

else
    # Syslog RFC 5424
    RFC5424_TS=$(date -u -r "$NOW" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -u -d "@$NOW" '+%Y-%m-%dT%H:%M:%S')
    MICRO=$(printf "%06d" $(( $(date +%N 2>/dev/null || echo 0) / 1000 )))
    RFC5424_TS="${RFC5424_TS}.${MICRO}+0000"

    # Build the syslog message with additional phrase
    MSG_SENT="<165>1 $RFC5424_TS $HOSTNAME.$APP 1234 ID47 [exampleSDID@32473 iut=\"3\" eventSource=\"Application\" eventID=\"1011\"] $MESSAGE_FINAL"

    # Escape double quotes for valid JSON
    ESCAPED_MSG_SENT=$(echo "$MSG_SENT" | sed 's/"/\\"/g')

    RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$(cat <<EOF
{
    "session": "$SESSION_ID",
    "sessionInfo": {
      "serverType": "syslog",
      "serverId": "$HOSTNAME"
    },
    "events": [
      {
        "thread": "$THREAD",
        "ts": "$SDL_TS",
        "sev": $SEV,
        "attrs": {
          "message": "$ESCAPED_MSG_SENT",
          "parser": "syslog",
          "dataset": "syslog_rfc_5424",
          "search_tag": "$SEARCH_TAG"
        }
      }
    ],
    "threads": [
      {"id": "$THREAD", "name": "syslog handler thread"}
    ]
}
EOF
)")
fi

# Extract HTTP status and response body
HTTP_STATUS=$(echo "$RESPONSE" | grep -o 'HTTP_STATUS:[0-9]*' | cut -d: -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "Response from $URL:"
echo "$RESPONSE_BODY"
echo "HTTP Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Event sent successfully to $URL"
    echo "Sent message content was:"
    echo "$MSG_SENT"
    echo
    echo "To locate this event in SDL, use the following EVENT SEARCH:"
    echo "1. Select scope (global, account, site, or group) - see: https://community.sentinelone.com/s/article/000006386"
    echo "2. Select view (filter: all) - see: https://community.sentinelone.com/s/article/000006372"
    echo "3. Select a time range (e.g., last 10 mins, 20 mins, 30 mins, etc.)"
    echo "4. Set search_tag = '$SEARCH_TAG'"
    echo "5. Press the purple search button"
    echo "See example screenshot: https://engage.sentinelone.com/viewer/f5f0560d78d39fa4d87f0432676a844c"
else
    echo "Failed to send event to $URL (Status: $HTTP_STATUS)"
fi
