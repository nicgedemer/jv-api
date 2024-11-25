variable "environment" {}
variable "aws_region" {}
variable "aws_account_id" {}
variable "cluster_logs_name" {}
variable "cluster_name" {}

variable "kms_alias" {
  default = "ecs-cluster"
}