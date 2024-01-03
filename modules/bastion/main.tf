# EC2 인스턴스 생성
resource "aws_instance" "bastion" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id                             // Pubilc 서브넷 할당
  vpc_security_group_ids = var.sg_ids
  associate_public_ip_address = true
  key_name = aws_key_pair.bastion_keypair.key_name      // key name
  tags = {
    Name = "hairpin_Bastion_Host"
  }
  user_data = var.user_data
}

resource "tls_private_key" "bastion_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = var.keypair_name
  public_key = tls_private_key.bastion_private_key.public_key_openssh
}

resource "local_file" "keypair_local" {
  filename        = "./keypair/${aws_key_pair.bastion_keypair.key_name}.pem"
  content         = tls_private_key.bastion_private_key.private_key_pem
  file_permission = "0600"
}
