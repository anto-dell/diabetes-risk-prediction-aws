#!/bin/bash
set -e

echo "Deploying EC2 Flask API..."
terraform init
terraform apply -auto-approve

echo ""
echo "Deployment complete. Wait 60-90 seconds for the instance to finish starting, then test with:"
echo ""
echo "curl -X POST \$(terraform output -raw api_url) \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"Pregnancies\":6,\"Glucose\":148,\"BloodPressure\":72,\"SkinThickness\":35,\"Insulin\":0,\"BMI\":33.6,\"DiabetesPedigreeFunction\":0.627,\"Age\":50}'"
