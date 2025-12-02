#!/bin/bash
set -e

# Azure Container Registry Setup Script
# This script creates an ACR and configures service principal for Azure DevOps

echo "================================================"
echo "Azure Container Registry Setup"
echo "================================================"

# Configuration - REPLACE THESE PLACEHOLDERS
ACR_NAME="<ACR_NAME>"                           # Must be globally unique, alphanumeric only
RESOURCE_GROUP="<RESOURCE_GROUP>"               # Azure resource group name
SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"             # Azure subscription ID
SERVICE_PRINCIPAL_NAME="<SERVICE_PRINCIPAL_NAME>" # Service principal name
LOCATION="eastus"                               # Azure region

echo ""
echo "Configuration:"
echo "  ACR Name: $ACR_NAME"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Location: $LOCATION"
echo ""

# Set the subscription
echo "Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
echo "Creating resource group (if not exists)..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table || echo "Resource group already exists"

# Create Azure Container Registry
echo ""
echo "Creating Azure Container Registry..."
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled false \
  --output table

# Get ACR ID
ACR_ID=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query "id" --output tsv)
echo "ACR ID: $ACR_ID"

# Create service principal with acrpush role
echo ""
echo "Creating service principal for Azure DevOps..."
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SERVICE_PRINCIPAL_NAME" \
  --scopes "$ACR_ID" \
  --role acrpush \
  --output json)

# Extract credentials
APP_ID=$(echo "$SP_OUTPUT" | jq -r '.appId')
PASSWORD=$(echo "$SP_OUTPUT" | jq -r '.password')
TENANT=$(echo "$SP_OUTPUT" | jq -r '.tenant')

echo ""
echo "================================================"
echo "Service Principal Created Successfully!"
echo "================================================"
echo ""
echo "Save these credentials for Azure DevOps service connection:"
echo ""
echo "  Docker Registry:       $ACR_NAME.azurecr.io"
echo "  Service Principal ID:  $APP_ID"
echo "  Service Principal Key: $PASSWORD"
echo "  Tenant ID:             $TENANT"
echo ""
echo "================================================"

# Login to ACR (for testing)
echo ""
echo "Logging into ACR..."
az acr login --name "$ACR_NAME"

echo ""
echo "Setup complete! Next steps:"
echo "1. Create a Docker Registry service connection in Azure DevOps"
echo "2. Use the credentials above"
echo "3. Update pipeline YAML files with the service connection name"
echo ""
