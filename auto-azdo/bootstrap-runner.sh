#!/bin/bash
set -e

# ==================================
# Default values (only optional args!)
# ==================================
AZDO_URL=""
AZDO_TOKEN=""
AZDO_POOL=""
AZDO_AGENT=""
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
# Detect OS and pick package
# ==================================
OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
  Linux*)   AGENT_PKG="vsts-agent-linux-x64-${AZDO_AGENT_VERSION}.tar.gz" ;;
  Darwin*)  AGENT_PKG="vsts-agent-osx-x64-${AZDO_AGENT_VERSION}.tar.gz" ;;
  MINGW*|MSYS*|CYGWIN*) AGENT_PKG="vsts-agent-win-x64-${AZDO_AGENT_VERSION}.zip" ;;
  *)
    echo "❌ Unsupported OS: $OS_TYPE"
    exit 1
    ;;
esac

# ==================================
# Install Agent
# ==================================
mkdir -p ~/myagent && cd ~/myagent

echo "⬇️  Downloading agent version $AZDO_AGENT_VERSION for $OS_TYPE..."
wget --show-progress --progress=bar:force:noscroll \
  "https://download.agent.dev.azure.com/agent/${AZDO_AGENT_VERSION}/${AGENT_PKG}" \
  -O "$AGENT_PKG"

# Extract (tar for Linux/Mac, unzip for Windows)
if [[ "$AGENT_PKG" == *.tar.gz ]]; then
  tar zxvf "$AGENT_PKG"
else
  unzip "$AGENT_PKG"
fi

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
