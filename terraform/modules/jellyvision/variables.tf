variable "environment" {}
variable "account_name" {}
variable "aws_account_id" {}
variable "aws_region" {}
variable "vpc_cidr" {}

variable "api_min_containers" {
  default = 1
}

variable "api_max_containers" {
  default = 1
}

variable "api_task_memory" {
  default = 1024
}

variable "api_task_cpu" {
  default = 256
}

variable "api_service_count" {
  default = 1
}

# target scaling
variable "cpu_target_value" {
  default = "50"
}

variable "memory_target_value" {
  default = "50"
}

variable "api_cpu_high_period" {
  default = "3600"
}

variable "api_memory_high_period" {
  default = "3600"
}

variable "api_task_count_high_period" {
  default = "3600"
}

variable "api_task_count_period" {
  default = "3600"
}