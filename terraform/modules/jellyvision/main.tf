module "ecr" {
  source = "../shared/ecr"

  ecr_name    = "${var.environment}-simpsons-api"
  environment = var.environment
}

module "cluster" {
  source = "../shared/ecs/fargate/cluster"

  environment       = var.environment
  aws_region        = var.aws_region
  aws_account_id    = var.aws_account_id
  cluster_name      = var.environment
  cluster_logs_name = "${var.environment}-cluster-logs"
}

module "api" {
  source = "../shared/ecs/fargate/external-service"

  environment                = var.environment
  vpc_cidr                   = var.vpc_cidr
  account_name               = var.account_name
  aws_region                 = var.aws_region
  aws_account_id             = var.aws_account_id
  enable_deletion_protection = var.environment == "prod" ? true : false
  service_name               = "simpsons"
  task_memory                = var.api_task_memory
  task_cpu                   = var.api_task_cpu
  cpu_target_value           = var.cpu_target_value
  memory_target_value        = var.memory_target_value
  service_count              = var.api_service_count
  min_containers             = var.api_min_containers
  max_containers             = var.api_max_containers
  record_name                = "simpsons"
  container_command          = ["bundle", "exec", "ruby", "simpsons_simulator.rb", "-p", "4567", "-o", "0.0.0.0"]
  container_entrypoint       = null

  cpu_high_period        = var.api_cpu_high_period
  memory_high_period     = var.api_memory_high_period
  task_count_high_period = var.api_task_count_high_period
  task_count_period      = var.api_task_count_period
}

module "api-waf" {
  source = "../shared/waf"

  environment                       = var.environment
  waf_name                          = "simpsons_api"
  aws_wafv2_web_acl_association_arn = module.api.aws_lb
}