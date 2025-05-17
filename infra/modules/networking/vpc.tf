# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table

resource "aws_vpc" "demo" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = join("-", [var.environment_name, "vpc"])
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_subnet" "demo" {
  count = var.no_of_public_subnet

  availability_zone       = var.availability_zones[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.demo.id

  tags = {
    Name = join("-", [var.environment_name, "public-subnet"])
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = join("-", [var.environment_name, "igw"])
  }
}

resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }
}

resource "aws_route_table_association" "demo" {
  count = var.no_of_public_subnet

  subnet_id      = aws_subnet.demo[count.index].id
  route_table_id = aws_route_table.demo.id
}

resource "aws_subnet" "demo_private" {
  count = var.no_of_private_subnet

  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(aws_vpc.demo.cidr_block, 8, 255 - count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.demo.id

  tags = {
    Name = join("-", [var.environment_name, "private-subnet"])
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_eip" "nat" {
  count = 1

  tags = {
    Name = join("-", [var.environment_name, "vpc"])
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  count         = 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.demo[count.index].id

  tags = {
    Name = join("-", [var.environment_name, "nat-gw"])
  }
}

resource "aws_route_table" "demo_private" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
  }
}

resource "aws_route_table_association" "demo_private" {
  count = var.no_of_private_subnet

  subnet_id      = aws_subnet.demo_private[count.index].id
  route_table_id = aws_route_table.demo_private.id
}
