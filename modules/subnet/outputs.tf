output "public_subnet_ids" {
  value = aws_subnet.public-subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private-subnet[*].id
}

output "public_subnet_names" {
  value = aws_subnet.public-subnet[*].tags.Name
}

output "private_subnet_names" {
  value = aws_subnet.private-subnet[*].tags.Name
}

output "private_subnet_az" {
  value = aws_subnet.private-subnet[*].availability_zone
}
