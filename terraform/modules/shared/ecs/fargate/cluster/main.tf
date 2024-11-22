# CloudWatch log groups

resource "aws_kms_key" "ecs" {
  description = "${var.environment}-ecs-cluster-key"

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Id" : "key-default-1",
  "Statement" : [ {
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${var.aws_account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Principal": { "Service": "logs.${var.aws_region}.amazonaws.com" },
      "Action": [ 
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }  
  ]
}
EOF
}

resource "aws_kms_alias" "a" {
  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.ecs.key_id
}

resource "aws_cloudwatch_log_group" "name" {
  name = var.cluster_logs_name

  kms_key_id        = aws_kms_key.ecs.arn
  retention_in_days = var.environment == "prod" ? 365 : 30 # 365 for COMPLIANCE on protected prod resources
}

resource "aws_ecs_cluster" "ecs" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.name.name
      }
    }
  }
}

# Cluster for Fargate 
resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.ecs.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}