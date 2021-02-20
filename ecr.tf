resource "aws_ecr_repository" "application" {
  count = var.image == "" ? 1 : 0
  name  = local.name

  image_scanning_configuration {
    scan_on_push = var.image_scanning
  }

  tags = local.tags
}

output "ecr_repository" {
  value = aws_ecr_repository.application.*.repository_url
}
