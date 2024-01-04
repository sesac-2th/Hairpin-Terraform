locals {
  region            = "ap-northeast-1"
  public_subnet_ids = data.aws_subnets.public_subnet_ids.ids
}

data "aws_ami" "ami_id" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_vpc" "vpc_id" {
  filter {
    name   = "tag:Name"
    values = ["hairpin-*"]
  }
}

data "aws_subnets" "public_subnet_ids" {
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.vpc_id.id}"]
  }
  filter {
    name   = "tag:Name"
    values = ["public-*"]
  }
}

data "aws_security_group" "sg" {
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.vpc_id.id}"]
  }
  filter {
    name   = "tag:Name"
    values = ["bastion-*"]
  }
}

# === user data 생성 -> ec2 init 파일 이라고 생각하면 됨 ===
data "template_file" "bastion_user_data" {
  template = file("./bastion_init.sh")
}

