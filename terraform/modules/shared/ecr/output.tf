output "ecr_arn" {
  value = aws_ecr_repository.ecr.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.ecr.repository_url
}