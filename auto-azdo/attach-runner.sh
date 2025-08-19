#!/bin/bash
set -e

# ==================================
# Help Function
# ==================================
usage() {
  echo "Usage: $0 -U <AZDO_URL> -P <AZDO_PROJECT> -N <AZDO_POOL_NAME>"
  echo
  echo "Options:"
  echo "  -U    Azure DevOps Organization URL (e.g., https://dev.azure.com/yourorg)"
  echo "  -P    Azure DevOps Project Name"
  echo "  -N    Azure DevOps Pool Name"
  echo "  -h    Show this help message"
  exit 1
}

# ==================================
# Parse Arguments
# ==================================
while getopts "U:P:N:h" opt; do
  case ${opt} in
    U) AZDO_URL="$OPTARG" ;;
    P) AZDO_PROJECT="$OPTARG" ;;
    N) AZDO_POOL="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Validate required args
if [[ -z "$AZDO_URL" || -z "$AZDO_PROJECT" || -z "$AZDO_POOL" ]]; then
  echo "❌ Missing required arguments."
  usage
fi

# ==================================
# Ensure Pool exists
# ==================================
POOL_ID=$(az pipelines pool list \
  --organization "$AZDO_URL" \
  --query "[?name=='$AZDO_POOL'].id" -o tsv)

if [ -z "$POOL_ID" ]; then
  echo "🔧 Pool '$AZDO_POOL' not found, creating..."
  az pipelines pool create \
    --name "$AZDO_POOL" \
    --organization "$AZDO_URL"
  POOL_ID=$(az pipelines pool list \
    --organization "$AZDO_URL" \
    --query "[?name=='$AZDO_POOL'].id" -o tsv)
else
  echo "✅ Pool '$AZDO_POOL' already exists (ID: $POOL_ID)"
fi

# ==================================
# Attach Pool to Project
# ==================================
echo "🔗 Attaching pool '$AZDO_POOL' to project '$AZDO_PROJECT'..."
az pipelines pool add \
  --pool-id "$POOL_ID" \
  --project "$AZDO_PROJECT" \
  --organization "$AZDO_URL" || true

echo "📋 Listing agents in pool '$AZDO_POOL'..."
az pipelines agent list \
  --pool-id "$POOL_ID" \
  --organization "$AZDO_URL" \
  -o table

echo "🎉 Pool '$AZDO_POOL' attached to project '$AZDO_PROJECT'"
