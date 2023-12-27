module "vpc" {
  source           = "./modules/vpc"
  vpc_name         = "hairpin-project-vpc"
  vpc_cidr         = "10.0.0.0/24"
  public_subnet_id = flatten(module.subnet[0].public_subnet_ids)[0]
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
  cluster_name         = "hairpin-cluster"
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
  source                         = "./modules/eks-cluster"
  main-region                    = "us-east-2"
  profile                        = var.profile
  rolearn                        = var.rolearn

  vpc_id                   = module.vpc.vpc_id
  private_subnets          = module.vpc.private_subnets
}

# AWS ALB Controller
module "aws_alb_controller" {
  source = "./modules/aws-alb-controller"

  main-region  = var.main-region
  env_name     = var.env_name
  cluster_name = var.cluster_name

  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
}