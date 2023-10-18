resource "aws_ecr_repository" "api" {
  name                 = "bootcamp-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    org         = "VTB",
    deployed_by = "Terraform IAC"
  }
}
