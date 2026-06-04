# S3 read policy — shared by EC2 and Lambda
resource "aws_iam_policy" "model_s3_policy" {
  name = "diabetes-model-s3-policy"
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.model_bucket.arn}/*"
    }]
  })
}
 
# Role for EC2 to use
resource "aws_iam_role" "ec2_role" {
  name = "diabetes-ec2-role"
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
 
# Allow EC2 to read the model from S3
resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.model_s3_policy.arn
}
 
# Allow EC2 to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
 
# Instance profile 
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "diabetes-ec2-profile"
  role = aws_iam_role.ec2_role.name
}