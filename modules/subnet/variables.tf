variable "vpc_id" {
}

variable "vpc_cidr" {
}

variable "subnet_az" {
  description = "Subnet AZ : 0(A)~3(D)"
}

variable "private_subnet_name" {
    default = ["eks", "rds"]
}

variable "public_subnet_cidr" {
    type = list(string)
}

variable "private_subnet_cidr" {
    type = list(string)
}

variable "public_subnet_count" {
}

variable "private_subnet_count" {
}