output "public_subnet_ids" {
  value = aws_subnet.public-subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private-subnet[*].id
}