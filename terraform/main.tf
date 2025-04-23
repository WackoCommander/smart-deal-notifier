provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# IAM Role and Policy for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "smart_deal_notifier_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda Permissions
resource "aws_iam_policy" "lambda_policy" {
  name        = "smart_deal_notifier_lambda_policy"
  description = "IAM policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "comprehend:DetectEntities",
          "sns:Publish",
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# DynamoDB Table to store processed deals
resource "aws_dynamodb_table"

