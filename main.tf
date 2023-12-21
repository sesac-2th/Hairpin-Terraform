module "vpc" {
  source = "./modules/vpc"
  vpc_name = "hairpin-project-vpc"
  vpc_cidr = "10.0.0.0/24"
  nat_count = 2
  public_subnet_id = flatten(module.subnet[*].public_subnet_ids)
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