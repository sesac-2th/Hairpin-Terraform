# ==== base network 설정 ====
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

module "security_group" {
  depends_on                        = [module.eks]
  source                            = "./modules/security-group"
  vpc_id                            = module.vpc.vpc_id
  allow_rds_ingress_sg_id           = ["${module.eks.node_security_group_id}"]
  allow_bastion_ingress_cidr_blocks = ["0.0.0.0/0"]
}

# ==== base network 설정 끝 ====


# ==== eks 설정 ====
module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "~> 19.0"
  cluster_name                   = local.cluster_name
  cluster_version                = "1.28"
  cluster_endpoint_public_access = false
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
      most_recent              = true
      service_account_role_arn = module.efs_role.iam_role_arn
    }
  }


  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = local.subnet_eks_nodegroup_ids
  control_plane_subnet_ids = local.subnet_eks_cluster_ids
  # EKS Managed Node Group(s)

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      AmazonEFSCSIDriverPolicy    = data.aws_iam_policy.efs_csi.arn
      CloudWatchAgentServerPolicy = data.aws_iam_policy.cw_agent.arn
    }
  }
  eks_managed_node_groups = {
    nodegroup = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

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
}

# ==== eks helm addon 서비스 생성 ====
module "eks_addon" {
  source = "./modules/helm"
  depends_on = [
    module.eks,
    module.eks_service_account,
    module.efs,
    module.external_dns_irsa_role
  ]

  namespace = "kube-system"

  helm_lb_name           = "aws-load-balancer-controller"
  helm_external_dns_name = "external-dns"
  helm_jenkins_name      = "jenkins"
  helm_argocd_name       = "argocd"

  # === set for lb ===
  eks_lb_service_account_name = module.eks_service_account.eks_lb_service_account_name
  lb_deploy_region            = local.region


  # === set for external-dns ===
  eks_external_dns_service_account_name = module.eks_service_account.external_dns_sc_name
  external_dns_deploy_region            = local.region

  # ==== set 공통 ====
  eks_cluster_name = local.cluster_name
  vpc_id           = module.vpc.vpc_id

}


# ==== eks 용 service account 생성 ====

module "eks_service_account" {
  depends_on              = [module.eks]
  source                  = "./modules/eks/service-account"
  lb_service_account_name = "aws-load-balancer-controller"
  namespace               = "kube-system"
  component               = "controller"
  lb_role_arn             = module.lb_role.iam_role_arn
  external_dns_sc_name    = "external-dns"
  external_dns_role_arn   = module.external_dns_irsa_role.iam_role_arn
  # efs_service_account_name = ["efs-csi-node-sa", "efs-csi-controller-sa"]
  # efs_role_arn             = module.efs_role.iam_role_arn
}


# # ==== eks 에서 사용할 aws 서비스 role 생성 ====

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "hairpin-lb_controller_iam_role"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "efs_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "hairpin-efs-csi-role"
  attach_efs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa", "kube-system:efs-csi-node-sa"]
    }
  }
}

module "external_dns_irsa_role" {
  depends_on = [module.eks]

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                  = "external-dns"
  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

# ==== efs 생성  ====
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
    "${data.aws_availability_zones.available.names[0]}" = {
      subnet_id = local.subnet_eks_nodegroup_ids[0]
    }
    "${data.aws_availability_zones.available.names[1]}" = {
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
      # cidr_blocks = module.vpc.private_subnets_cidr_blocks
      source_security_group_id = module.eks.node_security_group_id
    }
  }

  # Backup policy
  enable_backup_policy = false

  # Replication configuration
  create_replication_configuration = false
  replication_configuration_destination = {
    region = local.region
  }
}

# ==== eks helm jenkins 위한 storage class 생성 ====

module "efs_storage_class" {
  source = "./modules/eks/storageclass"
  depends_on = [
    module.efs
  ]
  efs_name = "jenkins-efs-pv"

  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  # == parameters ==
  provisioningMode = "efs-ap"
  efs_id           = module.efs.id
  directoryPerms   = "700"
}


#  ==== rds 설정 ====
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "hairpin-subent-group"
  subnet_ids = local.private_subnet_rds_ids
}

module "rds" {
  depends_on = [module.security_group]
  source     = "terraform-aws-modules/rds/aws"

  identifier = "hairpin-rds"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0.35"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t3.medium"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "hairpin"
  username = "admin"
  password = "adminadmin"
  port     = 3306

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = ["${module.security_group.rds_sg_id}"]

  allow_major_version_upgrade = true
  parameter_group_name        = "default.mysql8.0"

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]
  create_cloudwatch_log_group     = true

  skip_final_snapshot = true
  deletion_protection = false

  performance_insights_enabled = false
  # performance_insights_retention_period = 7
  # create_monitoring_role                = true
  # monitoring_interval                   = 60

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}

# ==== bastion ec2 설정 ====

module "bastion_ec2" {
  source       = "./modules/ec2"
  ami_id       = data.aws_ami.ami_id.id # amazon-linux-2
  subnet_id    = local.public_subnet_ids[0]
  ec2_sg_ids   = ["${module.security_group.bastion_sg_id}"]
  keypair_name = "hairpin-bastion"
  user_data    = data.template_file.bastion_user_data.rendered
}

# ==== S3 ====
module "s3" {
  source      = "./modules/s3"
  bucket_name = "hairpin-bucket"
}

# ==== ACM ====
module "cdn-acm" { # cloudfront 를 위한 인증서 -> 글로벌 서비스라 버지니아에 생성해야함 꼭!!!!
  providers = {
    aws = aws.virginia
  }
  source            = "./modules/acm"
  domain_name       = "hairpin.today"
  alternative_name  = ["*.hairpin.today"]
  route53_host_zone = data.aws_route53_zone.route53_hosting_zone.zone_id
}

module "alb-acm" { # alb 를 위한 인증서
  source            = "./modules/acm"
  domain_name       = "*.hairpin.today"
  route53_host_zone = data.aws_route53_zone.route53_hosting_zone.zone_id
}

