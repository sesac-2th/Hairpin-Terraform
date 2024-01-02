data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ami_id" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# === user data 생성 -> ec2 init 파일 이라고 생각하면 됨 ===
data "template_file" "bastion_user_data" {
  template = file("./bastion_init.sh")
}

data "aws_route53_zone" "route53_hosting_zone" {
  name         = "hairpin.today"
  private_zone = false
}

data "aws_iam_policy" "efs_csi" {
  name = "AmazonEFSCSIDriverPolicy"
}

data "aws_iam_policy" "cw_agent" {
  # name = "CloudWatchAgentServerPolicy" # Not included PutRetentionPolicy Permission
  name = "CloudWatchFullAccess" # Included PutRetentionPolicy Permission
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
  region = "ap-northeast-1"
  # 가용영역 당 서브넷 개수
  public_subnet_count  = 1
  private_subnet_count = 2

  public_subnet_ids        = data.aws_subnets.public_subnet_ids.ids
  private_subnet_ids       = data.aws_subnets.private_subnet_ids.ids
  subnet_eks_cluster_ids   = data.aws_subnets.subnet_eks_cluster_ids.ids
  subnet_eks_nodegroup_ids = data.aws_subnets.private_subnet_eks_nodegroup_ids.ids
  private_subnet_rds_ids   = data.aws_subnets.private_subnet_rds_ids.ids

  cluster_name                       = "hairpin-cluster"
  lb_controller_iam_role_name        = "hairpin-eks-aws-lb-role"
  lb_controller_service_account_name = "hairpin-aws-lb-svc-account"
  efs_name                           = "jenkins-efs-pv"
}
