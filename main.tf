module "vpc" {
  source = "./modules/vpc"
  vpc_name = "hairpin-project-vpc"
  vpc_cidr = "10.0.0.0/24"
  nat_count = 2
  public_subnet_id = flatten(module.subnet[*].public_subnet_ids)
  # 형석 (위에서 nat_count = 2로 주면 아래처럼 안해도 되는지)
  #enable_nat_gateway = true
  #one_nat_gateway_per_az = true
}

module "subnet" {
  source = "./modules/subnet"
  count = 2
  vpc_id = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
  public_subnet_count = local.public_subnet_count
  private_subnet_count = local.private_subnet_count
  public_subnet_cidr = flatten([for i in range(local.public_subnet_count) : [cidrsubnet(module.vpc.vpc_cidr, 3, count.index * 3)]])
  private_subnet_cidr = flatten([for i in range(local.private_subnet_count): [cidrsubnet(module.vpc.vpc_cidr, 3, count.index * 3 + i + 1)]])
  subnet_az = data.aws_availability_zones.available.names[count.index]
}

module "public_route_tb" {
  source = "./modules/routetb"
  vpc_id = module.vpc.vpc_id
  count = length(flatten(module.subnet[*].public_subnet_ids))
  rt_name = flatten(module.subnet[*].public_subnet_names)[count.index]
  subnet_id = flatten(module.subnet[*].public_subnet_ids)[count.index]

  routings = {
        igw = {
            dst_cidr = "0.0.0.0/0",
            dst_id = module.vpc.igw_id
        }
    }
}

module "private_route_tb" {
  source = "./modules/routetb"
  vpc_id = module.vpc.vpc_id
  count = length(flatten(module.subnet[*].private_subnet_ids))
  rt_name = flatten(module.subnet[*].private_subnet_names)[count.index]
  subnet_id = flatten(module.subnet[*].private_subnet_ids)[count.index]
  routings = {
        nat = {
            dst_cidr = "0.0.0.0/0",
            dst_id = flatten(module.subnet[*].private_subnet_az)[count.index] == data.aws_availability_zones.available.names[0] ? module.vpc.nat_id[0] : module.vpc.nat_id[1]
        }
    }
}

#module "collabnix_application_load_balancer" {
#  source = "./modules/application_load_balancer"
#}

module "security_group" {
  source = "../modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

module "acm" {
  source            = "../modules/acm"
  domain_name       = var.domain_name
  alternative_name  = var.alternative_name
}

module "application_load_balancer" {
  source            = "../modules/alb"
  project_name      = module.vpc.project_name
  alb_security_group_id   = module.security_group.alb_security_group_id
  public_subnet_ids = module.vpc.public_subnet_ids
  vpc_id            = module.vpc.vpc_id
  certificate_arn   = module.acm.certificate_arn
}

module "acm" {
  source            = "../modules/acm"
  domain_name       = var.domain_name
  alternative_name  = var.alternative_name
}