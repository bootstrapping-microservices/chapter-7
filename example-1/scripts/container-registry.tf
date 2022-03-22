# Creates a container registry on AWS so that you can publish your Docker images.



resource "aws_ecr_repository" "ecr" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
 }

tags = {
   Env = "prod"
 }

}
