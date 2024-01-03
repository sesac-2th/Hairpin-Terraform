resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.ami_id.id
  instance_type               = "t2.small"
  subnet_id                   = local.public_subnet_ids[0]
  key_name                    = aws_key_pair.ec2_keypair.key_name
  vpc_security_group_ids      = ["${data.aws_security_group.sg.id}"]
  associate_public_ip_address = true
  user_data                   = data.template_file.bastion_user_data.rendered

  tags = {
    Name = "hairpin-bastion"
  }
}


# === key pair 생성 및 local 에 저장하는 코드 ==== 
resource "tls_private_key" "ec2_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = "hairpin-key"
  public_key = tls_private_key.ec2_private_key.public_key_openssh
}

resource "local_file" "keypair_local" {
  filename        = "./keypair/${aws_key_pair.ec2_keypair.key_name}.pem"
  content         = tls_private_key.ec2_private_key.private_key_pem
  file_permission = "0600"
}
