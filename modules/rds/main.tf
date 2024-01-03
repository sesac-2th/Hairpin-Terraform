resource "aws_db_subnet_group" "hairpin-rds-subnet-group" {
  name       = var.db_subnet_group_name
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "hairpin-rds" {
  allocated_storage    = var.allocated_storage
  storage_type         = var.storage_type
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = var.username
  password             = var.password
  db_subnet_group_name = aws_db_subnet_group.hairpin-rds-subnet-group.id
  vpc_security_group_ids = var.security_group_ids  
  multi_az               = true
  skip_final_snapshot    = true
}

resource "aws_security_group" "rds-sg" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    security_groups = var.allow_rds_ingress_sg_id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
