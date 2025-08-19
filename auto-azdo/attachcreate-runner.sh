#!/bin/bash
set -e

# ==================================
# Help Function
# ==================================
usage() {
  echo "Usage: $0 -U <AZDO_URL> -P <AZDO_PROJECT> -N <AZDO_POOL_NAME> -T <AZDO_PAT>"
  echo
  echo "Options:"
  echo "  -U    Azure DevOps Organization URL (e.g., https://dev.azure.com/yourorg)"
  echo "  -P    Azure DevOps Project Name"
  echo "  -N    Azure DevOps Pool Name"
  echo "  -T    Azure DevOps Personal Access Token (PAT)"
  echo "  -h    Show this help message"
  exit 1
}

# ==================================
# Parse Arguments
# ==================================
while getopts "U:P:N:T:h" opt; do
  case ${opt} in
    U) AZDO_URL="$OPTARG" ;;
    P) AZDO_PROJECT="$OPTARG" ;;
    N) AZDO_POOL="$OPTARG" ;;
    T) AZDO_TOKEN="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Validate required args
if [[ -z "$AZDO_URL" || -z "$AZDO_PROJECT" || -z "$AZDO_POOL" || -z "$AZDO_TOKEN" ]]; then
  echo "❌ Missing required arguments."
  usage
fi

# ==================================
# Login with PAT
# ==================================
echo "🔑 Logging in to Azure DevOps..."
echo "$AZDO_TOKEN" | az devops login --organization "$AZDO_URL"

# ==================================
# Check or Create Pool
# ==================================
POOL_ID=$(az pipelines pool list \
  --organization "$AZDO_URL" \
  --query "[?name=='$AZDO_POOL'].id" -o tsv)

if [ -z "$POOL_ID" ]; then
  echo "🔧 Pool '$AZDO_POOL' not found, creating..."

  POOL_ID=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -u ":$AZDO_TOKEN" \
    -d "{\"name\": \"$AZDO_POOL\"}" \
    "$AZDO_URL/_apis/distributedtask/pools?api-version=7.1-preview.1" \
    | jq -r '.id')

  if [ "$POOL_ID" = "null" ] || [ -z "$POOL_ID" ]; then
    echo "❌ Failed to create pool"
    exit 1
  fi

  echo "✅ Created pool '$AZDO_POOL' (ID: $POOL_ID)"
else
  echo "✅ Pool '$AZDO_POOL' exists (ID: $POOL_ID)"
fi

# ==================================
# Attach Pool to Project
# ==================================
echo "🔗 Attaching pool '$AZDO_POOL' to project '$AZDO_PROJECT'..."

PROJECT_ID=$(az devops project show \
  --project "$AZDO_PROJECT" \
  --organization "$AZDO_URL" \
  --query id -o tsv)

# Cek apakah queue sudah ada
QUEUE_INFO=$(curl -s \
  -u ":$AZDO_TOKEN" \
  "$AZDO_URL/$AZDO_PROJECT/_apis/distributedtask/queues?api-version=7.1-preview.1" \
  | jq -r ".value[] | select(.pool.id==$POOL_ID)")

QUEUE_ID=$(echo "$QUEUE_INFO" | jq -r '.id')
QUEUE_NAME=$(echo "$QUEUE_INFO" | jq -r '.name')

if [ -z "$QUEUE_ID" ] || [ "$QUEUE_ID" = "null" ]; then
  echo "➕ Creating new queue for pool..."
  QUEUE_ID=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -u ":$AZDO_TOKEN" \
    -d "{\"scope\": {\"project\": {\"id\": \"$PROJECT_ID\"}}, \"pool\": {\"id\": $POOL_ID}}" \
    "$AZDO_URL/_apis/distributedtask/queues?api-version=7.1-preview.1" \
    | jq -r '.id')
  echo "✅ Queue created (ID: $QUEUE_ID)"
else
  echo "✅ Queue already exists (Name: $QUEUE_NAME, ID: $QUEUE_ID)"
fi

# ==================================
# Listing Agents Pool to Project
# ==================================
echo "📋 Listing agents in pool '$AZDO_POOL'..."
AGENTS=$(az pipelines agent list \
  --pool-id "$POOL_ID" \
  --organization "$AZDO_URL" \
  -o table)

if [ -z "$AGENTS" ]; then
  echo "⚠️  No agents registered in pool '$AZDO_POOL' yet."
else
  echo "$AGENTS"
fi


if [ -n "$QUEUE_ID" ] && [ "$QUEUE_ID" != "null" ]; then
  echo "🎉 Pool '$AZDO_POOL' successfully attached to project '$AZDO_PROJECT' (Queue ID: $QUEUE_ID)"
else
  echo "❌ Failed to attach pool '$AZDO_POOL' to project '$AZDO_PROJECT'"
  exit 1
fi
