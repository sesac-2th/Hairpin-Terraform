terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.2.0" # 변경
    }
  }
}

provider "aws" {
  region = local.region
}
