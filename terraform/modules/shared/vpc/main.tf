module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = var.environment
  cidr = var.vpc_cidr

  azs = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  private_subnets = ["${cidrsubnet(var.vpc_cidr, 8, 1)}", "${cidrsubnet(var.vpc_cidr, 8, 2)}", "${cidrsubnet(var.vpc_cidr, 8, 3)}"]
  public_subnets  = ["${cidrsubnet(var.vpc_cidr, 8, 6)}", "${cidrsubnet(var.vpc_cidr, 8, 7)}", "${cidrsubnet(var.vpc_cidr, 8, 8)}"]

  enable_nat_gateway      = true
  single_nat_gateway      = (var.environment == "prod" || var.environment == "production" ? false : true)
  one_nat_gateway_per_az  = false
  enable_vpn_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  enable_flow_log           = true
  flow_log_traffic_type     = "REJECT"
  flow_log_destination_type = "s3"
  flow_log_destination_arn  = aws_s3_bucket.s3_bucket.arn

  public_subnet_tags = {
    name         = "public-subnet"
    service      = "subnet"
    connectivity = "public"
    data_type    = "public"
    env          = var.environment
  }
  private_subnet_tags = {
    name         = "private-subnet"
    service      = "subnet"
    connectivity = "private"
    data_type    = "private"
    env          = var.environment
  }
  vpc_tags = {
    name    = "vpc"
    service = "vpc"
    cidr    = var.vpc_cidr
  }
  tags = {
    env = var.environment
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket              = "${var.bucket_name}-vpc-logs-${var.environment}-${var.aws_region}"
  object_lock_enabled = false
  force_destroy       = true

  tags = {
    env          = var.environment
    service      = "s3"
    connectivity = "private"
  }
}

resource "aws_s3_bucket_acl" "connectivity" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket]

  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.s3_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_db_subnet_group" "private" {
  name       = "${var.environment}-db-private"
  subnet_ids = flatten([module.vpc.private_subnets])
  tags = {
    service      = "rds"
    env          = "${var.environment}"
    connectivity = "private"
  }

  depends_on = [
    module.vpc
  ]
}

resource "aws_db_subnet_group" "public" {
  name       = "${var.environment}-db-public"
  subnet_ids = flatten([module.vpc.public_subnets])
  tags = {
    service      = "rds"
    env          = "${var.environment}"
    connectivity = "public"
  }

  depends_on = [
    module.vpc
  ]
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}"]
  }

  depends_on = [
    module.vpc
  ]
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