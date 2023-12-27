variable "vpc_id" {

}

variable "rt_association_count" {
}

variable "rt_name" {
  type = string
}

variable "subnet_id" {
  type = list(string)
}

variable "routings" {
}