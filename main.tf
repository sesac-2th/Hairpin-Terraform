module "vpc" {
  source = "./modules/vpc"
  vpc_name = "hairpin-vpc"
  vpc_cidr = "10.0.0.0/24"
  # nat_count = local.public_subnet_count
  # public_subnet_id = module.subnet.public_subnet_ids
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

