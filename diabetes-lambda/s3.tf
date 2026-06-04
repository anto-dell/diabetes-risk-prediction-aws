# S3 bucket to store the Lambda Layer zip.
# The dependencies (scikit-learn, pandas, numpy) are too large to upload
# directly to Lambda, so we upload to S3 first and reference it from there.
resource "aws_s3_bucket" "artifacts" {
  bucket        = "diabetes-lambda-artifacts-antonella-2026"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload the layer zip to S3
resource "aws_s3_object" "layer_zip" {
  bucket      = aws_s3_bucket.artifacts.id
  key         = "layer.zip"
  source      = data.archive_file.layer_zip.output_path
  source_hash = data.archive_file.layer_zip.output_base64sha256
}
