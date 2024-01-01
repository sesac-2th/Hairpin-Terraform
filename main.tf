module "vpc" {
  source           = "./modules/vpc"
  vpc_name         = "hairpin-project-vpc"
  vpc_cidr         = "10.0.0.0/24"
  public_subnet_id = flatten(module.subnet[0].public_subnet_ids)[0] # nat 생성할 public subnet
}

module "subnet" {
  source               = "./modules/subnet"
  count                = 2
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr
  public_subnet_count  = local.public_subnet_count
  private_subnet_count = local.private_subnet_count
  public_subnet_cidr   = flatten([for i in range(local.public_subnet_count) : [cidrsubnet(module.vpc.vpc_cidr, 3, count.index * 3)]])
  private_subnet_cidr  = flatten([for i in range(local.private_subnet_count) : [cidrsubnet(module.vpc.vpc_cidr, 3, count.index * 3 + i + 1)]])
  subnet_az            = data.aws_availability_zones.available.names[count.index]
  cluster_name         = local.cluster_name
}

module "public_route_tb" {
  source               = "./modules/routetb"
  vpc_id               = module.vpc.vpc_id
  rt_association_count = length(flatten(module.subnet[*].public_subnet_ids))
  rt_name              = "public-hairpin"
  subnet_id            = flatten(module.subnet[*].public_subnet_ids)

  routings = {
    igw = {
      dst_cidr = "0.0.0.0/0",
      dst_id   = module.vpc.igw_id
    }
  }
}

module "private_route_tb" {
  source               = "./modules/routetb"
  vpc_id               = module.vpc.vpc_id
  rt_association_count = length(flatten(module.subnet[*].private_subnet_ids))
  rt_name              = "private-hairpin"
  subnet_id            = flatten(module.subnet[*].private_subnet_ids)
  routings = {
    nat = {
      dst_cidr = "0.0.0.0/0",
      dst_id   = module.vpc.nat_id
    }
  }
}

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "~> 19.0"
  cluster_name                   = local.cluster_name
  cluster_version                = "1.28"
  cluster_endpoint_public_access = true

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  # 보관 기간은 default가 무제한이지만 비용 절감을 위해 90일로 설정
  cloudwatch_log_group_retention_in_days = 90

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = local.subnet_eks_nodegroup_ids
  control_plane_subnet_ids = local.subnet_eks_cluster_ids

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]

    iam_role_additional_policies = {
      AmazonEFSCSIDriverPolicy    = data.aws_iam_policy.efs_csi.arn
      CloudWatchAgentServerPolicy = data.aws_iam_policy.cw_agent.arn
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    nodegroup = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      # AutoScaler를 위해 tag를 붙임
      tags = {
        //For Cluster-Autoscaler Addon
        "k8s.io/cluster-autoscaler/enabled" : "true"
        "k8s.io/cluster-autoscaler/${module.eks.cluster_name}" : "true"
      }
    }
  }

  //  remote_access = {
  //    ec2_ssh_key               = module.key_pair.key_pair_name
  //    source_security_group_ids = [aws_security_group.remote_access.id]
  //  }
  manage_aws_auth_configmap = true
}

#######################################
### SeSAC (IAM_POLICY)
#######################################

data "aws_iam_policy" "cw_agent" {
  # name = "CloudWatchAgentServerPolicy" # Not included PutRetentionPolicy Permission
  name = "CloudWatchFullAccess" # Included PutRetentionPolicy Permission
}

data "aws_iam_policy" "efs_csi" {
  name = "AmazonEFSCSIDriverPolicy"
}

#######################################
### EFS
#######################################

# EFS CSI Driver
# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/efs-csi.html

# Create an Amazon EFS file system for Amazon EKS
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/efs-create-filesystem.md

# EFS Dynamic Provisioning
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/dynamic_provisioning/README.md#edit-storageclass

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.2"

  # File system
  name             = local.efs_name
  encrypted        = false
  performance_mode = "generalPurpose" # generalPurpose(default), maxIO
  throughput_mode  = "bursting"       # bursting(default), elastic, provisioned

  # File system policy
  attach_policy = false

  # Mount targets
  mount_targets = {
    "one" = {
      subnet_id = local.subnet_eks_nodegroup_ids[0]
    }
    "two" = {
      subnet_id = local.subnet_eks_nodegroup_ids[1]
    }
  }

  # Security Group
  create_security_group      = true
  security_group_name        = "${local.efs_name}-sg"
  security_group_description = "EFS security group for ${module.eks.cluster_name} EKS Cluster"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Backup policy
  enable_backup_policy = false

  # Replication configuration
  create_replication_configuration = false
  replication_configuration_destination = {
    region = local.region_name
  }
}

# StorageClass for EFS
resource "kubernetes_storage_class" "efs-sc" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = module.efs.id
    directoryPerms   = "700"
  }
}

############################
### RDS
############################

resource "aws_db_instance" "rds" {
  allocated_storage    = 20                 // 할당할 스토리지 용량
  engine               = "mysql"            // DB 엔진
  engine_version       = "8.0.35"           // DB 엔진 버전
  instance_class       = "db.t3.medium"     // 인스턴스 타입
  db_name              = var.db_name        // 기본으로 생성할 db이름
  username             = var.db_user_name
  password             = var.db_password
  parameter_group_name = "default.mysql8.0" // DB 파라메터
  skip_final_snapshot  = true               // 인스턴스 제거 시 최종 스냅샷을 만들지 않고 제거
  db_subnet_group_name = aws_db_subnet_group.rds.name
  identifier           = "hairpin-rds"
  vpc_security_group_ids  = [aws_security_group.rds.id]
  storage_encrypted = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  backup_retention_period = "7"
  auto_minor_version_upgrade = false
}

# RDS에서 사용할 서브넷그룹을 private subnet을 이용하여 생성
resource "aws_db_subnet_group" "rds" {
  name       = "hairpin-group"
  #subnet_ids = [for index, subnet in flatten([module.vpc.private_rds_subnets]) : subnet.id]
  subnet_ids = flatten(module.subnet[*].private_subnet_ids)
  tags = {
    Name = "hairpin-rds"
  }
}

# RDS에서 사용할 보안그룹 생성
resource "aws_security_group" "rds" {
  name        = "hairpin-rds"
  description = "hairpin-rds"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "hairpin-rds"
  }
}

# bastion과 eks클러스터 내부에서 3306으로 접근 가능하도록 rule설정
resource "aws_security_group_rule" "cluster-name-rds" {
  description       = "hairpin-rds allow from cluster"
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  source_security_group_id = aws_security_group.rds.id
  to_port           = 3306
  type              = "ingress"
}

variable "db_user_name" {
    description = "The username for the database"
    default = "user"
    type = string
    sensitive = true
}

# DB password는 직접 변경하는 걸로
variable "db_password" {
    description = "The password for the database"
    default = "password"
    type = string
    sensitive = true
}

variable "db_name" {
    description = "The name to use for the database"
    type = string
    default = "hairpindb"
}

#output "rds_endpoint" {
#  value = module.rds_instance.rds_endpoint
#}


####################################
### route 53
####################################

# get hosted zone details
# terraform aws data hosted zone
data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}

# create a record set in route 53
# terraform aws route 53 record
/*
resource "aws_route53_record" "site_domain" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}
*/