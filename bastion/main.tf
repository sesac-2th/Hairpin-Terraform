module "bastion_ec2" {
  source        = "../modules/ec2"
  ec2_name      = "hairpin-bastion"
  ami_id        = data.aws_ami.ami_id.id # amazon-linux-2
  instance_type = "t2.medium"
  subnet_id     = local.public_subnet_ids[0]
  ec2_sg_ids    = ["${data.aws_security_group.sg.id}"]
  user_data     = data.template_file.bastion_user_data.rendered
  keyfile_path  = "${path.module}/keypair/hairpin-bastion.pem"
}
