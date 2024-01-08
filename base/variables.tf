data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  region = "ap-northeast-1"
  # 가용영역 당 서브넷 개수
  public_subnet_count  = 1
  private_subnet_count = 2

  cluster_name = "hairpin-cluster"
}
