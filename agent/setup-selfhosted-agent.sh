#!/bin/bash
set -e

# Azure DevOps Self-Hosted Agent Setup Script
# This script installs Docker and sets up an Azure DevOps agent on Ubuntu/Debian

echo "================================================"
echo "Azure DevOps Self-Hosted Agent Setup"
echo "================================================"

# Configuration - REPLACE THESE PLACEHOLDERS
ORG="<ORG>"                     # Azure DevOps organization (e.g., mycompany)
PAT="<PAT>"                     # Personal Access Token with Agent Pools (read, manage) scope
POOL_NAME="<POOL_NAME>"         # Agent pool name (e.g., AzureAgent)
AGENT_NAME="$(hostname)-agent"  # Agent name (defaults to hostname)

# Azure DevOps URL
AZP_URL="https://dev.azure.com/$ORG"

echo ""
echo "Configuration:"
echo "  Organization: $ORG"
echo "  Agent Pool: $POOL_NAME"
echo "  Agent Name: $AGENT_NAME"
echo "  URL: $AZP_URL"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update package list
echo "Updating package list..."
apt-get update -y

# Install prerequisites
echo "Installing prerequisites..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo ""
    echo "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up the stable repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    echo "Docker installed successfully"
else
    echo "Docker is already installed"
fi

# Create agent user
echo ""
echo "Creating agent user..."
if ! id "azagent" &>/dev/null; then
    useradd -m -s /bin/bash azagent
    echo "User 'azagent' created"
else
    echo "User 'azagent' already exists"
fi

# Add agent user to docker group
echo "Adding azagent to docker group..."
usermod -aG docker azagent

# Create agent directory
AGENT_DIR="/home/azagent/myagent"
mkdir -p "$AGENT_DIR"
cd "$AGENT_DIR"

# Download agent
echo ""
echo "Downloading Azure DevOps agent..."
AGENT_VERSION=$(curl -s https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest | jq -r '.tag_name' | sed 's/v//')
AGENT_URL="https://vstsagentpackage.azureedge.net/agent/$AGENT_VERSION/vsts-agent-linux-x64-$AGENT_VERSION.tar.gz"

echo "Downloading version $AGENT_VERSION from $AGENT_URL"
curl -L -o vsts-agent.tar.gz "$AGENT_URL"

# Extract agent
echo "Extracting agent..."
tar zxvf vsts-agent.tar.gz

# Set ownership
chown -R azagent:azagent "$AGENT_DIR"

# Configure agent
echo ""
echo "Configuring agent..."
sudo -u azagent bash -c "cd $AGENT_DIR && ./config.sh \
  --unattended \
  --url '$AZP_URL' \
  --auth pat \
  --token '$PAT' \
  --pool '$POOL_NAME' \
  --agent '$AGENT_NAME' \
  --acceptTeeEula \
  --replace"

# Install and start agent service
echo ""
echo "Installing agent as a service..."
cd "$AGENT_DIR"
./svc.sh install azagent

echo "Starting agent service..."
./svc.sh start

# Verify installation
echo ""
echo "================================================"
echo "Agent Setup Complete!"
echo "================================================"
echo ""
echo "Agent Status:"
./svc.sh status

echo ""
echo "Troubleshooting:"
echo "  - View logs: cat $AGENT_DIR/_diag/*.log"
echo "  - Check status: sudo systemctl status vsts.agent.*"
echo "  - Restart agent: cd $AGENT_DIR && sudo ./svc.sh restart"
echo ""
echo "Docker group changes require logout/login for azagent user"
echo "To apply immediately: newgrp docker"
echo ""
echo "Verify agent appears in Azure DevOps:"
echo "  Organization Settings > Agent Pools > $POOL_NAME > Agents"
echo ""
