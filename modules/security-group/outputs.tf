output "bastion_sg_id" {
  description = "The ID of the security group"
  value       = try(aws_security_group.bastion.id, "")
}

output "rds_sg_id" {
  description = "The ID of the security group"
  value       = try(aws_security_group.rds.id, "")
}
