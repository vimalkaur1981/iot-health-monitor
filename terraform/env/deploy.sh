#!/usr/bin/env bash
set -euo pipefail

ENV=$1

if [[ -z "$ENV" ]]; then
  echo "Usage: ./deploy.sh <uat|prod>"
  exit 1
fi

ENV_DIR="terraform/env/$ENV"

if [[ ! -d "$ENV_DIR" ]]; then
  echo "Environment folder not found: $ENV_DIR"
  exit 1
fi

echo "🚀 Deploying Terraform for environment: $ENV"

cd "$ENV_DIR"

terraform init -upgrade
terraform plan -out=tfplan
terraform apply tfplan
