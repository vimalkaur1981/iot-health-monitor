#####################################################
# VPC
#####################################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
   Name = "group5-${terraform.workspace}-vpc"  # Workspace-specific name
    Env  = terraform.workspace               # Tag to identify environment
  }
}

#####################################################
# Public Subnets
#####################################################
# Define availability zones for public subnets
locals {
  public_subnets = {
    az1 = "us-east-1a"
    az2 = "us-east-1b"
  }
}
# Create public subnets in each AZ
resource "aws_subnet" "public" {
  for_each = local.public_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value

  # Generate CIDR block for each subnet
  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    8,
    index(keys(local.public_subnets), each.key)
  )

  map_public_ip_on_launch = true # Auto-assign public IPs to instances

  tags = {
    Name = "${terraform.workspace}-public-${each.value}"  # Workspace-specific name
    Env  = terraform.workspace
  }
}

#####################################################
# Private Subnets
#####################################################
# Define availability zones for private subnets
locals {
  private_subnets = {
    az1 = "us-east-1a"
    az2 = "us-east-1b"
  }
}
# Create private subnets in each AZ
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value

  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    8,
    index(keys(local.private_subnets), each.key) + 10
  )

  map_public_ip_on_launch = false

  tags = {
    Name = "${terraform.workspace}-private-${each.value}"  # Workspace-specific name
    Env  = terraform.workspace
  }
}

#####################################################
# Elastic IP for NAT Gateway
#####################################################
resource "aws_eip" "nat" {
  domain = "vpc"

   tags = {
    Name = "${terraform.workspace}-nat-eip"  # Workspace-specific
    Env  = terraform.workspace
  }
}

#####################################################
# Internet Gateway
#####################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace}-igw"
    Env  = terraform.workspace
  }
}

#####################################################
# Public Route Table
#####################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace}-public-rt"
    Env  = terraform.workspace
  }
}
# Route to Internet Gateway for public subnets
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

  # Note: Route table associations cannot have tags in AWS
}

#####################################################
# NAT Gateway
#####################################################
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["az1"].id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${terraform.workspace}-nat"
    Env  = terraform.workspace
  }
}

#####################################################
# Private Route Table
#####################################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace}-private-rt"
    Env  = terraform.workspace
  }
}

# Route to NAT Gateway for private subnets (internet access)
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
  
}

# Associate private route table to private subnets
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id

  # Note: Route table associations cannot have tags in AWS
}

