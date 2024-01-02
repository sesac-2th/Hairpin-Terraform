resource "aws_security_group" "rds" {
  vpc_id      = var.vpc_id         #생성할 위치의 VPC ID
  name        = "rds-sg"           #그룹 이름
  description = "Terraform rds SG" #설명
  ingress {
    from_port       = 3306                        #인바운드 시작 포트
    to_port         = 3306                        #인바운드 끝나는 포트
    protocol        = "tcp"                       #사용할 프로토콜
    security_groups = var.allow_rds_ingress_sg_id #허용할 IP 범위
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion" {
  vpc_id      = var.vpc_id                 #생성할 위치의 VPC ID
  name        = "bastion-sg"               #그룹 이름
  description = "Terraform bastion-ec2 SG" #설명
  ingress {
    from_port   = 22                                    #인바운드 시작 포트
    to_port     = 22                                    #인바운드 끝나는 포트
    protocol    = "tcp"                                 #사용할 프로토콜
    cidr_blocks = var.allow_bastion_ingress_cidr_blocks #허용할 IP 범위
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
