# Diabetes Risk Prediction API — EC2 Flask Solution

Portfolio Task 2 — Cloud Programming (DLBSEPCP01_E)
IU International University of Applied Sciences

A pre-trained scikit-learn diabetes prediction model deployed as a REST API on an AWS EC2 instance using Flask and Terraform.

---

## What it does

Hosts a Flask API on an EC2 t3.micro instance (Ubuntu 22.04, eu-central-1). The model and application code are stored in S3 and downloaded automatically on instance startup via a user_data script. A security group opens port 5000 for the API and port 22 for SSH.

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials (`aws configure`)

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
api_url = "http://<EC2_PUBLIC_IP>:5000/predict"
```

Wait 60-90 seconds after apply for the instance to finish its startup script before testing.

---

## How to test

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

> **Important:** Run destroy immediately after testing to avoid unexpected AWS charges. EC2 costs ~$0.01/hour when running.

---

## AWS Region

Deployed in **eu-central-1 (Frankfurt)**.

---

## Project structure

```
├── deploy.sh        # Automated deployment script
├── destroy.sh       # Automated teardown script
├── main.tf          # AWS provider configuration
├── ec2.tf           # EC2 instance, security group, key pair
├── s3.tf            # S3 bucket, model and app.py upload
├── iam.tf           # IAM role for EC2 (S3 read + CloudWatch)
├── outputs.tf       # API URL output
├── app.py           # Flask API
└── pima_best_pipeline.joblib  # Pre-trained scikit-learn model
```
