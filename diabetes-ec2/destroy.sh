#!/bin/bash
set -e

echo "Destroying EC2 Flask API infrastructure..."
terraform destroy -auto-approve

echo ""
echo "All resources destroyed. Check your AWS Console to confirm."
