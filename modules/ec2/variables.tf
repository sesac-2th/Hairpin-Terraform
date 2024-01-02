variable "ami_id" {
}

variable "ec2_sg_ids" {
  type = list(string)
}

variable "keypair_name" {
  type = string
}

variable "user_data" {

}

variable "subnet_id" {

}
