variable "db_subnet_group_name" {
  description = "Name for the DB subnet group"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
}

variable "allocated_storage" {
  description = "Allocated storage for RDS"
}

variable "storage_type" {
  description = "Storage type for RDS"
}

variable "engine" {
  description = "Database engine"
}

variable "engine_version" {
  description = "Database engine version"
}

variable "instance_class" {
  description = "RDS instance class"
}

variable "name" {
  description = "Name for the RDS instance"
}

variable "username" {
  description = "Username for the RDS instance"
}

variable "password" {
  description = "Password for the RDS instance"
}

variable "security_group_ids" {
  description = "List of security group IDs"
}

variable "security_group_name" {
  description = "Name for the security group"
}

variable "security_group_description" {
  description = "Description for the security group"
}

variable "vpc_id" {
  description = "ID of the VPC"
}

variable "db_port" {
  description = "Port for the database"
  default     = 3306
}

variable "allow_rds_ingress_sg_id" {
  type = list(string)
}