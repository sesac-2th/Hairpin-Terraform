terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.2.0" # 변경
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

locals {
  api_version = "client.authentication.k8s.io/v1beta1"
  args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  command     = "aws"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = local.api_version
    args        = local.args
    command     = local.command
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = local.api_version
      args        = local.args
      command     = local.command
    }
  }
}