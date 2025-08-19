#!/bin/bash
set -euo pipefail

# ===============================
# Colors & Logging
# ===============================
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

info_log() {
    echo -e "${BLUE}ℹ️ Info:${RESET} ${1}"
}

error_log() {
    echo -e "${RED}❌ Error:${RESET} ${1}" 1>&2
}

exit_with_error() {
    error_log "${1}"
    exit 1
}

# ===============================
# Usage / Help
# ===============================
usage() {
    echo -e "${BOLD}Usage:${RESET} $0 -O <ORG_NAME> -N <PAT_NAME> [-S \"<SCOPES>\"]"
    echo
    echo "Options:"
    echo "  -O    Azure DevOps Organization Name (required)"
    echo "  -N    Personal Access Token (PAT) Name (required)"
    echo "  -S    PAT Scopes (default: vso.code_write)"
    echo "  -h    Show this help message"
    echo
    echo "Example:"
    echo "  $0 -O sithanos -N fluxcd-token -S \"vso.code_write vso.build_execute\""
    echo
    echo "Documentation References:"
    echo " - PAT Scopes definitions: https://learn.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/oauth?view=azure-devops#scopes"
    echo " - CLI-based PAT creation example: https://github.com/jongio/azure-cli-awesome/blob/main/create-devops-pat.azcli"
    echo " - Additional PAT script example: https://gist.github.com/glennmusa/ca334c214de70e783a9c4976c7dcd58c"
    exit 1
}

# ===============================
# Parse Arguments
# ===============================
scopes="vso.code_write"  # default

while getopts "O:N:S:h" opt; do
  case ${opt} in
    O) organization_name="$OPTARG" ;;
    N) pat_name="$OPTARG" ;;
    S) scopes="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Validate required args
if [[ -z "${organization_name:-}" || -z "${pat_name:-}" ]]; then
  error_log "Missing required arguments."
  usage
fi

# ===============================
# Generate PAT via Azure DevOps REST API
# ===============================
uri="https://vssps.dev.azure.com/${organization_name}/_apis/Tokens/Pats?api-version=6.1-preview"
resource="https://management.core.windows.net/"
body="{ \"displayName\": \"${pat_name}\", \"scope\": \"${scopes}\" }"
headers="Content-Type=application/json"

info_log "Creating PAT '${pat_name}' in organization '${organization_name}'..."

token=$(az rest \
    --method post \
    --uri "$uri" \
    --resource "$resource" \
    --body "$body" \
    --headers "$headers" \
    --query "patToken.token" \
    --output tsv) || exit_with_error "Failed to create PAT in organization '${organization_name}'."

info_log "✅ Created PAT '${pat_name}' with scopes '${scopes}'!"
echo
echo -e "${YELLOW}${BOLD}👉 Copy & run the following commands to authenticate with Azure DevOps CLI:${RESET}"
echo "=========================================================================="
echo -e "${GREEN}export AZURE_DEVOPS_EXT_PAT=${token}${RESET}"
echo "az config set extension.use_dynamic_install=yes_without_prompt"
echo "echo \$AZURE_DEVOPS_EXT_PAT | az devops login --organization https://dev.azure.com/${organization_name}/"
echo "=========================================================================="
