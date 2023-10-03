resource "aws_ecr_repository" "api" {
  name                 = "bootcamp-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
