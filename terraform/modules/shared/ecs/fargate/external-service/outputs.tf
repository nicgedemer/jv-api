output "aws_lb" {
  value = aws_lb.web.arn
}

output "aws_ecs_task_definition_name" {
  value = one(aws_ecs_task_definition.definition[*].family)
}

output "aws_s3_bucket" {
  value = aws_s3_bucket.bucket.id
}