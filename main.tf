
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
resource "aws_lambda_function" "promtail_lambda_test" {
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


