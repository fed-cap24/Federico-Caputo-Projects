#Get available AZ in the region.
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Definition
resource "aws_vpc" "main" {
  cidr_block           = var.vpcCidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_VPC" : "VPC"}
  )
}

# VPC Flow Logs to CloudWatch
resource "aws_flow_log" "VpcFlowLog" {
  iam_role_arn    = aws_iam_role.vpc_fl_policy_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each                = { for i, v in var.PublicSubnet-List : i => v }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpcCidr, each.value.newbits, each.value.netnum)
  availability_zone       = data.aws_availability_zones.available.names[each.value.az]
  map_public_ip_on_launch = true
  tags                    = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_${each.value.name}" : each.value.name}
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each          = { for i, v in var.PrivateSubnet-List : i => v }
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpcCidr, each.value.newbits, each.value.netnum)
  availability_zone = data.aws_availability_zones.available.names[each.value.az]
  tags              = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_${each.value.name}" : each.value.name}
  )
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags   = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_IG" : "IG" }
  )
}

# Public Route Table
resource "aws_default_route_table" "publicRouteTable" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_Public_RT" : "Public_RT"}
  )
}

# EIP for NAT Gateway
resource "aws_eip" "nat_gateway" {
  count   = length(var.PrivateSubnet-List)
  domain  = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.PrivateSubnet-List)
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_Nat_Gateway_${count.index}" : "Nat_Gateway_${count.index}"}
  )
}

# Private Route Table
resource "aws_route_table" "private_route_table" {
  count  = length(var.PrivateSubnet-List)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_RT_${count.index}" : "RT_${count.index}"}
  )
}

# Private Subnets Association
resource "aws_route_table_association" "private" {
  count          = length(var.PrivateSubnet-List)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}