data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  public_subnet_count = 1
  private_subnet_count = 2
}