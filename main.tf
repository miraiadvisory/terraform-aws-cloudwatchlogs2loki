resource "aws_lambda_function" "cwl_stream_lambda" {
  filename         = "${path.module}/cwl2eslambda.zip"
  function_name    = var.name
  role             = aws_iam_role.lambda_elasticsearch_execution_role.arn
  handler          = "cwl2es.handler"
  source_code_hash = filebase64sha256("${path.module}/cwl2eslambda.zip")
  runtime          = "nodejs18.x"

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = var.security_group_ids
    ###security_group_ids = [aws_security_group.this_security_group.id]
  }

  environment {
    variables = {
      es_endpoint        = var.es_endpoint
      es_index_prefix    = var.es_index_prefix
      cwl_logstream_name = var.cwl_logstream_name
    }
  }
}
