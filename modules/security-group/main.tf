resource "aws_security_group" "sg" {
  vpc_id      = var.vpc_id      #생성할 위치의 VPC ID
  name        = var.sg_name     #그룹 이름
  description = var.description #설명
  ingress {
    from_port       = var.port                               #인바운드 시작 포트
    to_port         = var.port                               #인바운드 끝나는 포트
    protocol        = var.protocol                           #사용할 프로토콜
    security_groups = try(var.allow_rds_ingress_sg_id, null) #허용할 IP 범위
    cidr_blocks     = try(var.allow_bastion_ingress_cidr_blocks, null)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.sg_name}"
  }
}