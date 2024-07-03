resource "aws_ecr_repository" "application" {
  count = var.image == "" ? 1 : 0
  name  = local.name

  image_scanning_configuration {
    scan_on_push = var.image_scanning
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "application" {
  count = var.image == "" ? 1 : 0
  repository = aws_ecr_repository.application.*.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than ${var.ecr_untagged_lifetime}"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.ecr_untagged_lifetime
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire tagged images and keep last ${var.ecr_number_of_newest_tags}"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.ecr_tag_prefix_list
          countType = "imageCountMoreThan"
          countNumber   = var.ecr_number_of_newest_tags
        }
        action = {
          type = "expire"
        }
      },
    ]
  })

depends_on = [ aws_ecr_repository.application ]
}

output "ecr_repository" {
  value = aws_ecr_repository.application.*.repository_url
}
