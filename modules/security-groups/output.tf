output "alb_security_group_id" {
  value = aws_security_group.alb_security_group.id
}

output "eks_security_group_id" {
  value = aws_security_group.eks_security_group.id
}