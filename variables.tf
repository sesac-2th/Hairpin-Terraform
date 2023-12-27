variable "main-region" {
  type    = string
  default = "us-east-2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "public_subnet_ids" {
  depends_on = [module.subnet]
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["public-*"]
  }
}

data "aws_subnets" "private_subnet_ids" {
  depends_on = [module.subnet]
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["private-*"]
  }
}

data "aws_subnets" "subnet_eks_cluster_ids" {
  depends_on = [module.subnet]
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["public-*", "*-eks-*"]
  }
}

data "aws_subnets" "private_subnet_eks_nodegroup_ids" {
  depends_on = [module.subnet]
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*-eks-*"]
  }
}

data "aws_subnets" "private_subnet_rds_ids" {
  depends_on = [module.subnet]
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*-rds-*"]
  }
}

locals {
  # 가용영역 당 서브넷 개수
  public_subnet_count  = 1
  private_subnet_count = 2

  public_subnet_ids        = data.aws_subnets.public_subnet_ids.ids
  private_subnet_ids       = data.aws_subnets.private_subnet_ids.ids
  subnet_eks_cluster_ids   = data.aws_subnets.subnet_eks_cluster_ids.ids
  subnet_eks_nodegroup_ids = data.aws_subnets.private_subnet_eks_nodegroup_ids.ids
  private_subnet_rds_ids   = data.aws_subnets.private_subnet_rds_ids.ids
}


################################################################################
# Default Variables
################################################################################
variable "profile" {
  type    = string
  default = "default"
}

################################################################################
# EKS Cluster Variables
################################################################################

variable "rolearn" {
  description = "Add admin role to the aws-auth configmap"
  default = "arn:aws:iam::490454094730:user/hairpin"
}

variable "env_name" {
  type    = string
  default = "dev"
}