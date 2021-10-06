#
# This script performs the following steps: 
# 1. Creates a CloudWatch Log group  for Lambda function to write logs to
# 2. Creates a ZIP pacakge from Lambda source file(s)
# 3. Creates an IAM execution role for Lambda
# 4. Creates a Lambda function resource using local ZIP file as source
#

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  #kms_key_id        = var.cloudwatch_kms_key_arn
  retention_in_days = 731 # let's retain logs for 2 years to compare past runs
}

data "archive_file" "mylambda_archive" {
  source_file     = "${path.module}/src/lambda/ManageRdsSnapshots/main.py"
  output_path     = "${path.module}/dist/ManageRdsSnapshots.zip"
  type            = "zip"
}

resource "aws_lambda_function" "mylambda_func" {
  function_name     = var.lambda_name 

  handler           = "main.lambda_handler"
  role              = aws_iam_role.lambda_exec_role.arn
  runtime           = "python3.8"
  timeout           = 60

  filename          = data.archive_file.mylambda_archive.output_path
  source_code_hash  = data.archive_file.mylambda_archive.output_base64sha256

  environment {
    variables       = {
      DB_INSTANCE_ID = var.db_instance_id
      SNAPSHOT_MAX_AGE_IN_DAYS = var.snapshot_max_age_in_days
      SNAPSHOT_MAX_AGE_IN_MONTHS = var.snapshot_max_age_in_months
      MIN_DAYS_SINCE_LAST_SNAPSHOT  = var.min_days_since_last_snapshot
    }
  }

  tags             = local.common_tags
}

resource "aws_lambda_alias" "mylambda_latest" {
  name             = "${var.lambda_name}-Latest"
  description      = "Alias for latest Lambda version"
  function_name    = aws_lambda_function.mylambda_func.function_name
  function_version = "$LATEST"
}


# Create Lambda execution IAM role, giving permissions to access other AWS services

resource "aws_iam_role" "lambda_exec_role" {
  name                = "${var.app_shortcode}_Lambda_Exec_Role"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
      "Action": [
        "sts:AssumeRole"
      ],
      "Principal": {
          "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "LambdaAssumeRolePolicy"
      }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.app_shortcode}_Lambda_Policy"
  path        = "/"
  description = "IAM policy with minimum permissions for ${var.lambda_name} Lambda function"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:log-group:/aws/lambda/${var.lambda_name}",
        "arn:aws:logs:*:*:log-group:/aws/lambda/${var.lambda_name}:*"
      ],
      "Effect": "Allow"
    }, 
    {
      "Action": [
        "rds:CreateDBSnapshot",
        "rds:DeleteDBSnapshot",
        "rds:DescribeDBSnapshots",
        "rds:DescribeDBSnapshotAttributes"
      ],
      "Resource": [
        "arn:aws:rds:${var.aws_region}:${local.account_id}:db:${var.db_instance_id}", 
        "arn:aws:rds:${var.aws_region}:${local.account_id}:snapshot:*"
      ], 
      "Effect": "Allow"
    }
  ]
}
EOF
}

# arn:aws:rds:${var.aws_region}:${local.account_id}:db:*
# arn:aws:rds:${var.aws_region}:${local.account_id}:db:${var.db_instance_id}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


