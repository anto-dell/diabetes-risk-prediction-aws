# Generate a private key
resource "tls_private_key" "ed25519" {
  algorithm = "ED25519"
}
 
# Register the key in AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "diabetes-key"
  public_key = tls_private_key.ed25519.public_key_openssh
}
 
# Save the private key to your MacBook so you can use it
resource "local_file" "private_key" {
  content         = tls_private_key.ed25519.private_key_openssh
  filename        = "${path.module}/diabetes-key.pem"
  file_permission = "0400"
}
 
# Find the latest Ubuntu 22.04 image 
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Ubuntu's official AWS account
 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
 
# Security group
resource "aws_security_group" "ec2_sg" {
  name        = "diabetes-api-sg"
  description = "Allow Flask and SSH"
 
  # Allow anyone to call the API
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Allow SSH access - inbound traffic 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# The EC2 instance
resource "aws_instance" "diabetes_api" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.generated_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
 
  # This script runs automatically when the instance first starts
  user_data = <<-EOF
    #!/bin/bash
    set -e  # Stop immediately if any command fails
 
    # Redirect all output to a log file for debugging
    exec > /var/log/user-data.log 2>&1
 
    # Update and install python + AWS CLI
    apt-get update -y
    apt-get install -y python3-pip awscli
 
    # Create a virtual environment and install the ML libraries inside it
    # (avoids pip version conflicts entirely)
    apt-get install -y python3-venv
    python3 -m venv /home/ubuntu/venv
    /home/ubuntu/venv/bin/pip install flask boto3 scikit-learn imbalanced-learn pandas numpy joblib
 
    # Download the app AND the model file from S3
    aws s3 cp s3://${aws_s3_bucket.model_bucket.id}/app.py /home/ubuntu/app.py
    aws s3 cp s3://${aws_s3_bucket.model_bucket.id}/pima_best_pipeline.joblib /home/ubuntu/pima_best_pipeline.joblib
 
    # Fix permissions on everything
    chown -R ubuntu:ubuntu /home/ubuntu/
 
    # Start the Flask app using the venv's Python
    cd /home/ubuntu
    sudo -u ubuntu nohup /home/ubuntu/venv/bin/python3 app.py > /home/ubuntu/diabetes-api.log 2>&1 &
 
    echo "Setup complete. Flask app started."
  EOF
 
  tags = {
    Name = "diabetes-api"
  }
}
 
# Print the API URL when terraform apply finishes
output "api_url" {
  value = "http://${aws_instance.diabetes_api.public_ip}:5000/predict"
}