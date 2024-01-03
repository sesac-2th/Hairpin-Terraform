variable "user_data" {}
variable "subnet_id" {}
variable "vpc_id" {}
variable "ami_id" {}

variable "instance_type" {
  default = "t2.medium"
}

variable "sg_ids" {
  type = list(string)
}

variable "keypair_name" {
  type = string
}



