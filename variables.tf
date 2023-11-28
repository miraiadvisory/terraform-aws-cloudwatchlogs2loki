variable "vpc_id" {
  type = string
}

variable "loki_index_prefix" {
  type    = string
  default = ""
}

variable "loki_endpoint" {
  type        = string
  description = "This is the Loki Write API compatible endpoint that you want to write logs to, either promtail or Loki."
  default     = "http://localhost:8080/loki/api/v1/push"
}

variable "cwl_logstream_name" {
  type    = string
  default = ""
}

variable "log_group_names" {
  type        = set(string)
  description = "List of CloudWatch Log Group names to create Subscription Filters for."
  default     = []
}

variable "username" {
  type        = string
  description = "The basic auth username, necessary if writing directly to Grafana Cloud Loki."
  default     = ""
}

variable "password" {
  type        = string
  description = "The basic auth password, necessary if writing directly to Grafana Cloud Loki."
  sensitive   = true
  default     = ""
}

variable "bearer_token" {
  type        = string
  description = "The bearer token, necessary if target endpoint requires it."
  sensitive   = true
  default     = ""
}

variable "cloudwatch_loggroup_name" {
  type = string
}

variable "cloudwatch_loggroup_retention" {
  type    = string
  default = 30
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "subnets" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  default     = 60
}
