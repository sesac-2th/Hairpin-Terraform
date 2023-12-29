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
      subnet_id = module.vpc.private_subnets[0]
    }
    "two" = {
      subnet_id = module.vpc.private_subnets[1]
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
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  # Backup policy
  enable_backup_policy = false

  # Replication configuration
  create_replication_configuration = false
  replication_configuration_destination = {
    region = var.region
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
