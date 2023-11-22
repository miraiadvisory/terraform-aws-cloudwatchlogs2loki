variable "vpc_id" {
  type = string
}

variable "loki_endpoint" {
  type = string
}

variable "log_endpoint" {
  type    = string
  default = "logs.eu-west-1.amazonaws.com"
}

variable "loki_index_prefix" {
  type    = string
  default = ""
}

variable "cwl_logstream_name" {
  type    = string
  default = ""
}

variable "cloudwatch_loggroup_name" {
  type = string
}

variable "cloudwatch_loggroup_retention" {
  type    = string
  default = 30
}

variable "name" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}
