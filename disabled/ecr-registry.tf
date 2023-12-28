module "ecr_repo" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 1.6"

  repository_name = var.ecr_repo_name
  repository_type = "private"

  repository_image_tag_mutability = "IMMUTABLE" # IMMUTABLE, MUTABLE

  manage_registry_scanning_configuration = false
  registry_scan_type                     = "BASIC" # ENHANCED, BASIC

  repository_encryption_type = "AES256" # KMS, AES256

  create_lifecycle_policy = false
  create_registry_policy  = false

}

output "ecr_url" {
  description = "URL of ECR Repository"
  value       = module.ecr_repo.repository_url
}

data "aws_caller_identity" "current" {}

output "ecr_registry_authentication_command" {
  description = "Command of ECR Registry Authentication"
  value       = "aws ecr get-login-password --region region | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.region.amazonaws.com"
}
