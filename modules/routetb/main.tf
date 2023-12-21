resource "aws_route_table" "route_table" {
  vpc_id = var.vpc_id
#   count = var.rt_count
  tags = {
    Name = "rt-${var.rt_name}"
  }
}

resource "aws_route_table_association" "route_table_association" {
#   count = length(flatten(aws_route_table.route_table))
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.route_table.id
}

# resource "aws_route" "mydefaultroute" {
#   route_table_id         = aws_route_table.myrt.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.akbun-igw.id
# }

resource "aws_route" "route_rule" {


  route_table_id =  aws_route_table.route_table.id
  destination_cidr_block = each.value.dst_cidr

  for_each = var.routings

  gateway_id = substr(each.value.dst_id,0,3) =="igw" ? each.value.dst_id : null
#   instance_id               = substr(each.value.dst_id,0,2) == "i-" ? each.value.dst_id : null
  nat_gateway_id = substr(each.value.dst_id,0,3) == "nat" ? each.value.dst_id : null
}