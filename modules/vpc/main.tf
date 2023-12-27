resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    "Name" = "${var.vpc_name}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "hairpin-igw"
  }
}

# NAT 게이트웨이가 사용할 Elastic IP생성
resource "aws_eip" "eip" {
  domain     = "vpc" #생성 범위 지정
  depends_on = [aws_internet_gateway.igw]
  lifecycle {
    create_before_destroy = true
  }
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id #EIP 연결
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "hairpin-nat"
  }
}