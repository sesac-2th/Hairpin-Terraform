variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  description = "VPC CIDR BLOCK : x.x.x.x/x"
  //default     = "10.0.0.0/16"
}

variable "public_subnet_id" {
  type = string
}
