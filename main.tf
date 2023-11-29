#-------------------------------------------------------------------------------
# IAM role assigned to the lambda function
#-------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_loki_execution_role" {
  name               = "${var.function_name}_lambda_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#-------------------------------------------------------------------------------
# IAM policy assigned to lambda IAM role to be able to execute in VPC
#-------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_loki_execution_policy" {
  role       = aws_iam_role.lambda_loki_execution_role.id
  policy_arn = data.aws_iam_policy.lambda_vpc_execution.arn
}
data "aws_iam_policy" "lambda_vpc_execution" {
  name = "AWSLambdaVPCAccessExecutionRole"
}

#-------------------------------------------------------------------------------
# IAM policies attached to lambda IAM role
#-------------------------------------------------------------------------------

resource "aws_iam_role_policy" "lambda_loki_execution_policy" {
  name   = "${var.function_name}_lambda_loki_execution_policy"
  role   = aws_iam_role.lambda_loki_execution_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "es:ESHttpPost",
      "Resource": "arn:aws:es:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

#-------------------------------------------------------------------------------
# Lambda function
#-------------------------------------------------------------------------------

resource "aws_lambda_function" "promtail_lambda" {
  filename         = "${path.module}/main.zip"
  function_name    = var.function_name
  role             = aws_iam_role.lambda_loki_execution_role.arn
  handler          = "main"
  source_code_hash = filebase64sha256("${path.module}/main.zip")
  runtime          = "go1.x"
  timeout          = var.timeout

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = var.security_group_ids
    ###security_group_ids = [aws_security_group.this_security_group.id]
  }

  environment {
    variables = {
      WRITE_ADDRESS            = var.loki_endpoint
      LOKI_INDEX_PREFIX        = var.loki_index_prefix
      CWL_LOGSTREAM_NAME       = var.cwl_logstream_name
      BEARER_TOKEN             = var.bearer_token
      KEEP_STREAM              = var.keep_stream
      EXTRA_LABELS             = var.extra_labels
      USERNAME                 = var.username
      PASSWORD                 = var.password
      OMIT_EXTRA_LABELS_PREFIX = "true"
    }
  }
}

#-------------------------------------------------------------------------------
# Lambda outbound traffic
#-------------------------------------------------------------------------------

resource "aws_security_group" "this_security_group" {
  name        = "${var.function_name}_lambda_sg"
  description = "Allow outbound traffic fom this Lambda"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
  }
}

#-------------------------------------------------------------------------------
# Subscribe to CloudWatch log-groups
#-------------------------------------------------------------------------------

data "aws_cloudwatch_log_group" "loggroup" {
  name = var.cloudwatch_loggroup_name
}

data "aws_region" "current" {
}

resource "aws_lambda_permission" "loki_allow" {
  statement_id  = "loki-allow"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${data.aws_cloudwatch_log_group.loggroup.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs_to_loki" {
  depends_on      = [aws_lambda_permission.loki_allow]
  name            = "${var.function_name}_cloudwatch_logs_to_loki"
  log_group_name  = data.aws_cloudwatch_log_group.loggroup.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.promtail_lambda.arn
}
