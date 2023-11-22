
resource "aws_iam_role" "lambda_loki_execution_role" {
  name               = "${var.name}_lambda_execution_role"
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

resource "aws_security_group" "this_security_group" {
  name        = "${var.name}_lambda_sg"
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

resource "aws_iam_role_policy" "lambda_loki_execution_policy" {
  name   = "${var.name}_lambda_loki_execution_policy"
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

resource "aws_lambda_function" "promtail_lambda" {
  filename         = "${path.module}/lambda-promtail.zip"
  function_name    = var.name
  role             = aws_iam_role.lambda_loki_execution_role.arn
  handler          = "lambda-promtail"
  source_code_hash = filebase64sha256("${path.module}/lambda-promtail.zip")
  runtime          = "go1.x"

  # vpc_config {
  #   subnet_ids         = var.subnets
  #   security_group_ids = var.security_group_ids
  #   ###security_group_ids = [aws_security_group.this_security_group.id]
  # }

  # environment {
  #   variables = {
  #     es_endpoint        = var.es_endpoint
  #     es_index_prefix    = var.es_index_prefix
  #     cwl_logstream_name = var.cwl_logstream_name
  #   }
  # }
}

resource "aws_lambda_permission" "loki_allow" {
  statement_id  = "loki_allow"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.promtail_lambda.arn
  principal     = var.log_endpoint
  source_arn    = "${data.aws_cloudwatch_log_group.loggroup.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs_to_loki" {
  depends_on      = [aws_lambda_permission.cloudwatch_allow]
  name            = "${var.name}_cloudwatch_logs_to_loki"
  log_group_name  = data.aws_cloudwatch_log_group.loggroup.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.promtail_lambda.arn
}
