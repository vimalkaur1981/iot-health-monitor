# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "g5-vpc"
  }
}

locals {
  public_subnets = {
    az1 = "us-east-1a"
    az2 = "us-east-1b"
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value

  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    8,
    index(keys(local.public_subnets), each.key)
  )

  map_public_ip_on_launch = true
}


# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "default_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate route table to both public subnets
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
