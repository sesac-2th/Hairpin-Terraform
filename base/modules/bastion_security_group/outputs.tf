output "bastion_sg_id" {
  description       = "The ID of the Security Group"
  value             = try(aws_security_group.bastion_sg.id, "")
}