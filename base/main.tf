# ==== base network 설정 ====
module "vpc" {
  source           = "../modules/vpc"
  vpc_name         = "hairpin-project-vpc"
  vpc_cidr         = "10.0.0.0/24"
  public_subnet_id = flatten(module.subnet[0].public_subnet_ids)[0] # nat 생성할 public subnet
}

module "subnet" {
  source               = "../modules/subnet"
  count                = 2
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr
  public_subnet_count  = local.public_subnet_count
  private_subnet_count = local.private_subnet_count
  public_subnet_cidr   = flatten([for i in range(local.public_subnet_count) : [cidrsubnet(module.vpc.vpc_cidr, 3, count.index * 3)]])
  private_subnet_cidr  = flatten([for i in range(local.private_subnet_count) : [cidrsubnet(module.vpc.vpc_cidr, 3, count.index * 3 + i + 1)]])
  subnet_az            = count.index * 3 - 1 >= 0 ? data.aws_availability_zones.available.names[count.index * 3 - 1] : data.aws_availability_zones.available.names[0]
  cluster_name         = local.cluster_name
}

module "public_route_tb" {
  source               = "../modules/routetb"
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
  source               = "../modules/routetb"
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
  source                            = "../modules/security-group"
  vpc_id                            = module.vpc.vpc_id
  allow_bastion_ingress_cidr_blocks = ["0.0.0.0/0"]
  allow_rds_ingress_sg_id           = null
  sg_name                           = "bastion-sg"
  port                              = 22
  protocol                          = "tcp"
  description                       = "Terraform bastion sg"
}

# ==== base network 설정 끝 ====
