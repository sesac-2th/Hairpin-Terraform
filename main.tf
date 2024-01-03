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

#########################################
### EKS
#########################################

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
  manage_aws_auth_configmap = true
}


############################################
### IAM_POLICY (SeSAC)
############################################

data "aws_iam_policy" "cw_agent" {
  # name = "CloudWatchAgentServerPolicy" # Not included PutRetentionPolicy Permission
  name = "CloudWatchFullAccess" # Included PutRetentionPolicy Permission
}

data "aws_iam_policy" "efs_csi" {
  name = "AmazonEFSCSIDriverPolicy"
}

############################################
### EFS (SeSAC)
############################################

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
      cidr_blocks = module.eks.node_security_group_id
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

module "hairpin-rds" {
  source = "./modules/rds"
  db_subnet_group_name   = "rds-subnet-group"
  subnet_ids             = local.private_subnet_rds_ids
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.medium"
  name                   = "rds"
  username               = "admin"
  password               = "password"
  security_group_ids     = [aws_security_group.rds-sg.id]
  security_group_name    = "hairpin-rds-sg"
  security_group_description = "Security group for RDS in us-east-2"
  vpc_id                 = module.vpc.vpc_id
  allow_rds_ingress_sg_id    = ["${module.eks.node_security_group_id}"]
}

resource "aws_security_group" "rds-sg" {
  name        = "${local.cluster_name}-rds-sg"
  description = "${local.cluster_name}-rds-sg"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "${local.cluster_name}-rds-SG"
  }
}

resource "aws_security_group_rule" "sg-cluster-to-rds" {
  description       = "${local.cluster_name}-rds allow from EKS cluster"
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds-sg.id
  source_security_group_id = module.eks.node_security_group_id
  to_port           = 3306
  type              = "ingress"
}

#############################################
### Bastion Host EC2
#############################################

module "bastion_ec2" {
  depends_on   = [module.bastion_sg]
  source       = "./modules/bastion"
  ami_id       = data.aws_ami.ami_id.id                    # amazon-linux-2
  subnet_id    = local.public_subnet_ids[0]
  vpc_id       = module.vpc.vpc_id
  sg_ids   = ["${module.bastion_sg.bastion_sg_id}"]
  keypair_name = "${local.cluster_name}_BastionHost"
  user_data    = data.template_file.bastion_user_data.rendered
}

module "bastion_sg" {
  depends_on            = [module.eks]
  source                = "./modules/bastion_security_group"
  vpc_id                = module.vpc.vpc_id
}