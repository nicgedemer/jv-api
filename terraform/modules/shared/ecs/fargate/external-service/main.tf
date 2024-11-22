data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id     = data.aws_caller_identity.current.account_id
  current_region = data.aws_region.current.name
}

data "aws_ecr_repository" "service_image" {
  name = "${var.environment}-simpsons-api"
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.account_name}"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:name"
    values = ["private-subnet"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:name"
    values = ["public-subnet"]
  }
}

locals {
  non_ephemeral = (var.environment == "prod" || var.environment == "miami" || var.environment == "staging")  ? true : false
  prod          = var.environment == "prod" ? true : false
}

# task definition
resource "aws_ecs_task_definition" "definition" {
  family                   = "${var.environment}-${var.service_name}"
  execution_role_arn       = aws_iam_role.ecs_web.arn
  task_role_arn            = aws_iam_role.ecs_web.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "${var.environment}-${var.service_name}",
    "image": "${data.aws_ecr_repository.service_image.repository_url}:${var.image_tag}",
    "essential": true,
    "command": ${jsonencode(var.container_command)},
    "environment": [
      {
        "name": "AWS_REGION",
        "value": "${var.aws_region}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${var.container_port}
      }
    ],
    "linuxParameters":{
      "initProcessEnabled": true
    },
    "logConfiguration": {
    "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.name.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "${var.environment}"
        }
    }
  }
]
TASK_DEFINITION
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  # lifecycle {
  #   ignore_changes = [container_definitions]
  # }
}



resource "aws_kms_key" "cmk" {
  description = "${var.environment}-${var.service_name}-key"

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
resource "aws_cloudwatch_log_group" "name" {
  name = "${var.environment}-${var.service_name}"

  kms_key_id        = aws_kms_key.cmk.arn
  retention_in_days = var.environment == "prod" ? 365 : 30
}

# service creation
resource "aws_ecs_service" "ecs" {
  name                               = "${var.environment}-${var.service_name}"
  cluster                            = var.environment
  task_definition                    = aws_ecs_task_definition.definition.arn
  desired_count                      = var.service_count
  enable_execute_command             = true
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 100

  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = flatten(["${data.aws_subnets.private.ids}"])
    security_groups  = ["${aws_security_group.ecs.id}"]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "${var.environment}-${var.service_name}"
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    create_before_destroy = true
    #ignore_changes        = [task_definition, desired_count]
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_iam_role" "ecs_web" {
  name                 = "${var.environment}-${var.service_name}-ecs_role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume_role_policy.json
  managed_policy_arns  = [aws_iam_policy.ecs_inline_policy_web.arn, "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  max_session_duration = var.max_session_duration
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs_inline_policy_web" {
  name = "${var.environment}-${var.service_name}-ecs-policy"

  policy = jsonencode(
    {
      "Statement" : [
        {
          "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecs:TagResource",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:CreateLogGroup",
            "logs:CreateLogDelivery",
            "ecs:RunTask",
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        },
        {
          "Action" : [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey",
            "ssm:GetParameters",
            "ssm:GetParametersByPath",
            "secretsmanager:GetSecretValue"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:secretsmanager:*:*:secret:*",
            "arn:aws:kms:*:*:key/*",
            "arn:aws:ssm:*:*:parameter/*"
          ]
        },
        {
          "Action" : "iam:PassRole",
          "Condition" : {
            "StringLike" : {
              "iam:PassedToService" : "ecs-tasks.amazonaws.com"
            }
          },
          "Effect" : "Allow",
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "ecs:TagResource",
          "Resource" : "*"
        },
        {
          "Action" : [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        }
      ],
      "Version" : "2012-10-17"
    }
  )
}

resource "aws_security_group" "ecs" {
  name        = "${var.environment}-${var.service_name}-ecs"
  description = "${var.environment}-${var.service_name}-ecs"
  vpc_id      = data.aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port       = 4567
    to_port         = 4567
    protocol        = "TCP"
    security_groups = ["${aws_security_group.alb.id}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    service = "security-group"
    name    = "${var.environment}-${var.service_name}-ecs"
  }
}

# load balancer

resource "aws_lb_target_group" "web" {
  name                          = "${var.environment}-${var.service_name}-lb-tg" 
  port                          = var.target_group_port
  protocol                      = var.target_group_protocol
  target_type                   = var.target_group_target_type
  vpc_id                        = data.aws_vpc.vpc.id
  load_balancing_algorithm_type = var.load_balancing_algorithm_type

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "web" {
  name_prefix                = "miami"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = flatten(["${data.aws_subnets.public.ids}"])
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields
  idle_timeout               = var.idle_timeout
  enable_http2               = var.enable_http2

  dynamic "access_logs" {
    for_each = local.non_ephemeral ? [1] : []
    content {
      bucket  = aws_s3_bucket.bucket.id
      prefix  = "${var.environment}-${var.service_name}"
      enabled = true
    }
  }

  depends_on = [aws_s3_bucket_policy.allow_load_balancer]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "alb" {
  name        = "${var.environment}-${var.service_name}-alb"
  description = "${var.environment}-${var.service_name}-alb"
  vpc_id      = data.aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    service = "security-group"
    name    = "${var.environment}-${var.service_name}-alb"
  }
}

# load balancer 5xx alarm
resource "aws_cloudwatch_metric_alarm" "alb-5xx" {
  alarm_name          = "${var.environment}-${var.service_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "200"
  dimensions = {
    LoadBalancer = "${aws_lb.web.name}"
  }
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.sns.arn]
  ok_actions      = [aws_sns_topic.sns.arn]

  treat_missing_data = "notBreaching"
}

# load balancer response time
resource "aws_cloudwatch_metric_alarm" "alb-rt" {
  alarm_name          = "${var.environment}-${var.service_name}-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "500"
  dimensions = {
    LoadBalancer = "${aws_lb.web.name}"
  }
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.sns.arn]
  ok_actions      = [aws_sns_topic.sns.arn]

  treat_missing_data = "notBreaching"
}

# alb unhealthy host cost
resource "aws_cloudwatch_metric_alarm" "unhealthy" {
  alarm_name          = "${var.environment}-${var.service_name}-unhealthy-host"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  dimensions = {
    LoadBalancer = "${aws_lb.web.name}"
  }
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.sns.arn]
  ok_actions      = [aws_sns_topic.sns.arn]

  treat_missing_data = "notBreaching"
}

# acm certificate for load balancer
data "aws_acm_certificate" "issued" {
  domain   = "${var.environment}.jv-magic.com"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "web" {
  name         = "${var.environment}.jv-magic.com"
  private_zone = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2019-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# route 53 route to load balancer
resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.web.zone_id
  name    = var.record_name
  type    = var.record_type

  alias {
    name                   = "dualstack.${aws_lb.web.dns_name}"
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = false
  }
}

resource "aws_appautoscaling_policy" "target_cpu" {
  name               = "${var.environment}-${var.service_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scale_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.cpu_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "target_mem" {
  name               = "${var.environment}-${var.service_name}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scale_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.memory_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.environment}/${var.environment}-${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_containers
  max_capacity       = var.max_containers

  depends_on = [
    aws_ecs_service.ecs
  ]
}

# Alarms

resource "aws_sns_topic" "sns" {
  name = "ecs-external-alarms"
}

resource "aws_sns_topic_subscription" "notifications" {
  topic_arn = aws_sns_topic.sns.arn
  protocol  = "email"
  endpoint  = "nicgedemer@gmail.com"
}

resource "aws_cloudwatch_metric_alarm" "ecs-cpu-high" {
  alarm_name          = "${var.environment}-${var.service_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cpu_high_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_high_period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  dimensions = {
    ClusterName = "${var.environment}"
    ServiceName = "${var.environment}-${var.service_name}"
  }

  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.sns.arn]
  ok_actions      = [aws_sns_topic.sns.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs-mem-high" {
  alarm_name          = "${var.environment}-${var.service_name}-ecs-mem-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.memory_high_evaluation_period
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.memory_high_period
  statistic           = "Average"
  threshold           = var.memory_high_threshold
  dimensions = {
    ClusterName = "${var.environment}"
    ServiceName = "${var.environment}-${var.service_name}"
  }
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.sns.arn]
  ok_actions      = [aws_sns_topic.sns.arn]
}


resource "aws_cloudwatch_metric_alarm" "ecs-running-task-count-high" {
  alarm_name          = "${var.environment}-${var.service_name}-ecs-running-task-count-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.task_count_high_evaluation_period
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = var.task_count_high_period
  statistic           = "Sum"
  threshold           = var.task_count_high_threshold
  dimensions = {
    ClusterName = "${var.environment}"
    ServiceName = "${var.environment}-${var.service_name}"
  }
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.sns.arn]
  ok_actions      = [aws_sns_topic.sns.arn]

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "ecs-running-task-count-none" {
  alarm_name          = "${var.environment}-${var.service_name}-ecs-running-task-count-none"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.task_count_none_evaluation_period
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = var.task_count_period
  statistic           = "Sum"
  threshold           = var.task_count_none
  dimensions = {
    ClusterName = "${var.environment}"
    ServiceName = "${var.environment}-${var.service_name}"
  }
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.sns.arn]
  ok_actions      = [aws_sns_topic.sns.arn]

  treat_missing_data = "notBreaching"
}

resource "aws_s3_bucket_policy" "allow_load_balancer" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::127311923021:root",
                  "arn:aws:iam::${local.account_id}:root"
                ]
            },
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::miami-jv-load-balancer-logs",
                "arn:aws:s3:::miami-jv-load-balancer-logs/*"
            ]
        }
    ]
  })
}

resource "aws_s3_bucket" "bucket" {
  bucket              = "${var.environment}-jv-load-balancer-logs"
  object_lock_enabled = false

  tags = {
    resource = "s3"
  }

  force_destroy = local.non_ephemeral ? false : true
}

resource "aws_s3_bucket_acl" "private-web" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.bucket]
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse-web" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}