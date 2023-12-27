resource "aws_subnet" "public-subnet" {
  count             = var.public_subnet_count
  vpc_id            = var.vpc_id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = var.subnet_az
  tags = {
    Name = "public-${var.subnet_az}"
  }
}

resource "aws_subnet" "private-subnet" {
  count             = var.private_subnet_count
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.subnet_az
  tags = {
    Name = "private-${var.private_subnet_name[count.index]}-${var.subnet_az}"
  }
}