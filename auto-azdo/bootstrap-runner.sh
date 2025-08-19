#!/bin/bash
set -e

# ==================================
# Default values
# ==================================
AZDO_URL=""
AZDO_TOKEN=""
AZDO_POOL="runner-thanos"
AZDO_AGENT="agent-mossad"
AZDO_WORK="_work"
AZDO_AGENT_VERSION="4.259.0"

# ==================================
# Usage helper
# ==================================
usage() {
  echo "Usage: $0 -U <URL> -T <PAT> -N <PoolName> -A <AgentName> [-W <WorkDir>] [-V <AgentVersion>]"
  echo
  echo "  -U   Azure DevOps organization URL (e.g. https://dev.azure.com/<org>)"
  echo "  -T   Personal Access Token (PAT)"
  echo "  -N   Agent Pool Name"
  echo "  -A   Agent Name"
  echo "  -W   Work directory (default: _work)"
  echo "  -V   Agent version (default: 4.259.0)"
  exit 1
}

# ==================================
# Parse options
# ==================================
while getopts "U:T:N:A:W:V:" opt; do
  case $opt in
    U) AZDO_URL="$OPTARG" ;;
    T) AZDO_TOKEN="$OPTARG" ;;
    N) AZDO_POOL="$OPTARG" ;;
    A) AZDO_AGENT="$OPTARG" ;;
    W) AZDO_WORK="$OPTARG" ;;
    V) AZDO_AGENT_VERSION="$OPTARG" ;;
    *) usage ;;
  esac
done

# ==================================
# Validate required inputs
# ==================================
if [[ -z "$AZDO_URL" || -z "$AZDO_TOKEN" || -z "$AZDO_POOL" || -z "$AZDO_AGENT" ]]; then
  echo "❌ Missing required arguments!"
  usage
fi

# ==================================
# Install Agent
# ==================================
mkdir -p ~/myagent && cd ~/myagent

echo "⬇️  Downloading agent version $AZDO_AGENT_VERSION..."
wget -q https://vstsagentpackage.azureedge.net/agent/${AZDO_AGENT_VERSION}/vsts-agent-linux-x64-${AZDO_AGENT_VERSION}.tar.gz
tar zxvf vsts-agent-linux-x64-${AZDO_AGENT_VERSION}.tar.gz

# ==================================
# Configure Agent
# ==================================
./config.sh --unattended \
  --url "$AZDO_URL" \
  --auth pat \
  --token "$AZDO_TOKEN" \
  --pool "$AZDO_POOL" \
  --agent "$AZDO_AGENT" \
  --acceptTeeEula \
  --work "$AZDO_WORK"

# ==================================
# Install & Start as Service
# ==================================
sudo ./svc.sh install
sudo ./svc.sh start

echo "🎉 Runner '$AZDO_AGENT' registered in pool '$AZDO_POOL' (URL: $AZDO_URL)"
