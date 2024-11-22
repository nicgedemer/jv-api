variable "environment" {}
variable "account_name" {}
variable "service_count" {}
variable "service_name" {}
variable "record_name" {}
variable "task_cpu" {}
variable "task_memory" {}
variable "aws_account_id" {}
variable "aws_region" {}
variable "min_containers" {}
variable "max_containers" {}

variable "container_entrypoint" {
  default = []
  type    = list(any)
}

variable "container_command" {
  default = []
  type    = list(any)
}

variable "container_port" {
  default = 4567
}

variable "image_tag" {
  default = "latest"
}

variable "vpc_cidr" {}

variable "record_type" {
  default = "A"
}

# variable "ttl" {
#   default = "300"
# }

variable "validation_method" {
  default = "DNS"
}


variable "sse_algorithm" {
  default = "AES256"
}

variable "idle_timeout" {
  default = 400
}

variable "drop_invalid_header_fields" {
  default = false
}

variable "enable_deletion_protection" {
  default = false
}

variable "enable_http2" {
  default = false
}

variable "load_balancing_algorithm_type" {
  default = "least_outstanding_requests"
}

variable "target_group_port" {
  default = 80
}

variable "target_group_protocol" {
  default = "HTTP"
}

variable "target_group_target_type" {
  default = "ip"
}

# cloudwatch alerts
# cpu high
variable "cpu_high_threshold" {
  default = "90"
}

variable "cpu_high_period" {
  default = "60"
}

variable "cpu_high_evaluation_period" {
  default = "3"
}

# memory high
variable "memory_high_threshold" {
  default = "90"
}

variable "memory_high_period" {
  default = "60"
}

variable "memory_high_evaluation_period" {
  default = "3"
}

# task count high
variable "task_count_high_threshold" {
  default = "3"
}

variable "task_count_high_period" {
  default = "60"
}

variable "task_count_high_evaluation_period" {
  default = "3"
}

# task count 0
variable "task_count_none" {
  default = "1"
}

variable "task_count_period" {
  default = "60"
}

variable "task_count_none_evaluation_period" {
  default = "1"
}

# target scaling
variable "cpu_target_value" {
  default = "30"
}

variable "memory_target_value" {
  default = "70"
}

variable "max_session_duration" {
  default = "43200"
}