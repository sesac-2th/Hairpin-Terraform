resource "aws_instance" "ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = aws_key_pair.ec2_keypair.key_name
  vpc_security_group_ids      = var.ec2_sg_ids
  associate_public_ip_address = true
  user_data                   = var.user_data

  tags = {
    Name = "${var.ec2_name}"
  }
}


# === key pair 생성 및 local 에 저장하는 코드 ==== 
resource "tls_private_key" "ec2_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = var.ec2_name
  public_key = tls_private_key.ec2_private_key.public_key_openssh
}

resource "local_file" "keypair_local" {
  filename        = var.keyfile_path
  content         = tls_private_key.ec2_private_key.private_key_pem
  file_permission = "0600"
}
