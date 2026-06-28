#!/bin/bash
set -e

echo "Destroying Lambda + API Gateway infrastructure..."
terraform destroy -auto-approve

echo ""
echo "All resources destroyed. Check your AWS Console to confirm."
