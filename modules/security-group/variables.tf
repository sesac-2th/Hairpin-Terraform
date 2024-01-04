variable "sg_name" {}
variable "port" {}
variable "protocol" {}
variable "description" {}

variable "vpc_id" {
  type = string
}

variable "allow_rds_ingress_sg_id" {
  type = list(string)
}

variable "allow_bastion_ingress_cidr_blocks" {
  type = list(string)
}