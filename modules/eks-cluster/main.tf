module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "~> 19.0"
  cluster_name                   = "hairpin-cluster-xeok"
  cluster_version                = "1.28"
  cluster_endpoint_public_access = true
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
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = local.subnet_eks_nodegroup_ids
  control_plane_subnet_ids = local.subnet_eks_cluster_ids
  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    nodegroup-xeok = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }

  //  remote_access = {
  //    ec2_ssh_key               = module.key_pair.key_pair_name
  //    source_security_group_ids = [aws_security_group.remote_access.id]
  //  }

  # aws-auth configmap
  #manage_aws_auth_configmap = true
  #create_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = var.rolearn
      username = "skanyi"
      groups   = ["system:masters"]
    },
  ]

  tags = {
    env       = "dev"
    terraform = "true"
  }
}