# Step 1: Build the Lambda Layer locally (installs Python dependencies).
# This runs "pip install" on the Mac terminal into a .build/layer/python folder.
# Terraform re-runs this only if requirements.txt changes.

resource "null_resource" "build_layer" {
  triggers = {
    reqs_hash = filesha256("${path.module}/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOT
set -euo pipefail
rm -rf ${path.module}/.build/layer
mkdir -p ${path.module}/.build/layer/python

python3 -m pip install \
  -r ${path.module}/requirements.txt \
  -t ${path.module}/.build/layer/python \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.11 \
  --only-binary=:all: \
  --quiet

# Strip files that are not needed at runtime to stay under the 250 MB limit.
cd ${path.module}/.build/layer/python
find . -type d -name "__pycache__"  -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc"                    -delete 2>/dev/null || true
find . -type f -name "*.pyo"                    -delete 2>/dev/null || true
find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "*.egg-info"  -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "tests"       -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "test"        -exec rm -rf {} + 2>/dev/null || true
# Remove large sklearn sample datasets (not needed)
rm -rf ./sklearn/datasets/data 2>/dev/null || true

echo "Layer size after stripping: $(du -sh . | cut -f1)"
EOT
  }
}

# Zip the installed packages
data "archive_file" "layer_zip" {
  depends_on  = [null_resource.build_layer]
  type        = "zip"
  source_dir  = "${path.module}/.build/layer"
  output_path = "${path.module}/.build/layer.zip"
}

# Register the zip as a Lambda Layer
resource "aws_lambda_layer_version" "deps" {
  layer_name          = "diabetes-python-deps"
  s3_bucket           = aws_s3_bucket.artifacts.id
  s3_key              = aws_s3_object.layer_zip.key
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256
  compatible_runtimes = ["python3.11"]
}


# Step 2: Copy handler + model into a staging folder, then zip the folder.
# Use source_dir (not individual source blocks) because the model
# is a binary file — filebase64() would corrupt it by storing base64 text.

resource "null_resource" "stage_lambda" {
  triggers = {
    handler_hash = filesha256("${path.module}/handler.py")
    model_hash   = filemd5("${path.module}/pima_best_pipeline.joblib")
  }

  provisioner "local-exec" {
    command = <<EOT
set -euo pipefail
mkdir -p ${path.module}/.build/lambda-src
cp ${path.module}/handler.py ${path.module}/.build/lambda-src/
cp ${path.module}/pima_best_pipeline.joblib ${path.module}/.build/lambda-src/
EOT
  }
}

data "archive_file" "lambda_zip" {
  depends_on  = [null_resource.stage_lambda]
  type        = "zip"
  source_dir  = "${path.module}/.build/lambda-src"
  output_path = "${path.module}/.build/lambda.zip"
}

# Step 3: Create the Lambda function.

resource "aws_lambda_function" "predict" {
  function_name    = "diabetes-predict"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.11"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Attach the layer with scikit-learn / pandas / numpy
  layers = [aws_lambda_layer_version.deps.arn]

  # 512 MB RAM is enough for this model; timeout of 30s is generous
  memory_size = 512
  timeout     = 30
}

# Allow API Gateway to invoke this Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.predict.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
