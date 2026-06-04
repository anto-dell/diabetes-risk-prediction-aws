resource "aws_s3_bucket" "model_bucket" {
  bucket        = "diabetes-model-antonella-2026"
  force_destroy = true
}
# Adding this because AWS kept consuming resources because terraform did not delete the S3 bucket

resource "aws_s3_bucket_public_access_block" "model_bucket_block" {
  bucket = aws_s3_bucket.model_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload the trained model to S3
resource "aws_s3_object" "model_file" {
  bucket = aws_s3_bucket.model_bucket.id
  key    = "pima_best_pipeline.joblib"
  source = "${path.module}/pima_best_pipeline.joblib"
  etag   = filemd5("${path.module}/pima_best_pipeline.joblib")
}

# Upload app.py to S3 so EC2 can download it on startup
resource "aws_s3_object" "app_file" {
  bucket = aws_s3_bucket.model_bucket.id
  key    = "app.py"
  source = "${path.module}/app.py"
  etag   = filemd5("${path.module}/app.py")
}