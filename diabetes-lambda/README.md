# Diabetes Risk Prediction API — Lambda Serverless Solution

Portfolio Task 2 — Cloud Programming (DLBSEPCP01_E)
IU International University of Applied Sciences

A pre-trained scikit-learn diabetes prediction model deployed as a serverless REST API on AWS Lambda + API Gateway using Terraform.

---

## What it does

Deploys the model as an AWS Lambda function (Python 3.11, 512 MB, 30s timeout) triggered via API Gateway HTTP API. The model is bundled directly in the deployment zip. Python dependencies (scikit-learn, pandas, numpy, imbalanced-learn) are packaged as a Lambda Layer and stored in S3.

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials (`aws configure`)
- Python 3.11 (for building the Lambda Layer locally)

---

## How to deploy

**Option 1 — Automated (recommended):**
```bash
chmod +x deploy.sh
./deploy.sh
```

**Option 2 — Manual:**
```bash
terraform init
terraform apply
```

Terraform will output the API URL:
```
api_url = "https://<API_ID>.execute-api.eu-central-1.amazonaws.com/predict"
```

---

## How to test

```bash
curl -X POST https://<API_ID>.execute-api.eu-central-1.amazonaws.com/predict \
  -H "Content-Type: application/json" \
  -d '{
    "Pregnancies": 6,
    "Glucose": 148,
    "BloodPressure": 72,
    "SkinThickness": 35,
    "Insulin": 0,
    "BMI": 33.6,
    "DiabetesPedigreeFunction": 0.627,
    "Age": 50
  }'
```

Expected response:
```json
{"prediction": "Diabetes", "probability": 0.7986}
```

---

## How to destroy

**Option 1 — Automated:**
```bash
chmod +x destroy.sh
./destroy.sh
```

**Option 2 — Manual:**
```bash
terraform destroy
```

> **Important:** Run destroy after testing to clean up all AWS resources.

---

## AWS Region

Deployed in **eu-central-1 (Frankfurt)**.

---

## Project structure

```
├── deploy.sh          # Automated deployment script
├── destroy.sh         # Automated teardown script
├── main.tf            # AWS provider configuration
├── lambda.tf          # Lambda Layer build, Lambda function, API Gateway permission
├── apigateway.tf      # API Gateway HTTP API, route, stage, integration
├── s3.tf              # S3 bucket for Lambda Layer zip
├── iam.tf             # IAM role for Lambda (CloudWatch logs only)
├── outputs.tf         # API URL output
├── handler.py         # Lambda handler
├── requirements.txt   # Python dependencies for Lambda Layer
└── pima_best_pipeline.joblib  # Pre-trained scikit-learn model
```
