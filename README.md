# Diabetes Risk Prediction API — AWS Cloud Deployment

Portfolio Task 2 — Cloud Programming (DLBSEPCP01_E)
IU International University of Applied Sciences

A pre-trained scikit-learn machine learning model deployed as a REST API on AWS using two different architectures. The model predicts diabetes risk based on 8 clinical input features and returns a JSON response with a prediction and probability score.

---

## Project Structure

```
├── diabetes-api/       # Solution 1: EC2-based Flask API
└── diabetes-lambda/    # Solution 2: Serverless Lambda + API Gateway
```

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials (`aws configure`)
- Python 3.x (only needed for local testing)

---

## Solution 1 — EC2 (Flask API)

### What it does
Hosts a Flask API on an EC2 t3.micro instance. The model and application code are stored in S3 and downloaded on startup. A security group opens port 5000 for the API and port 22 for SSH.

### How to deploy

```bash
cd diabetes-api
terraform init
terraform apply
```

Terraform will output the API URL:
```
api_url = "http://<EC2_PUBLIC_IP>:5000/predict"
```

### How to test

```bash
curl -X POST http://<EC2_PUBLIC_IP>:5000/predict \
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

### How to destroy

```bash
terraform destroy
```

> **Important:** Run `terraform destroy` immediately after testing to avoid unexpected AWS charges.

---

## Solution 2 — Lambda + API Gateway (Serverless)

### What it does
Deploys the model as an AWS Lambda function triggered via API Gateway HTTP API. The model is bundled directly in the deployment zip. Python dependencies are packaged as a Lambda Layer.

### How to deploy

```bash
cd diabetes-lambda
terraform init
terraform apply
```

Terraform will output the API URL:
```
api_url = "https://<API_ID>.execute-api.eu-central-1.amazonaws.com/predict"
```

### How to test

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

### How to destroy

```bash
terraform destroy
```

---

## AWS Region

Both solutions are deployed in **eu-central-1 (Frankfurt)**.

---

## Cost

Both deployments together cost approximately **$4.31** during development and testing.
- EC2: ~$0.011/hour when running — destroy immediately after use
- Lambda: ~$0 at low traffic (pay per invocation)
