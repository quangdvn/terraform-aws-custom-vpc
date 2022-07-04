resource "aws_vpc" "terra_vpc" { # Custom VPC
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    "Name" = "Custom VPC"
  }
}

resource "aws_subnet" "terra_private_subnet" { # Custom Private Subnet
  count             = length(var.private_subnet)
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = var.private_subnet[count.index]
  availability_zone = var.availability_zone[count.index % length(var.availability_zone)]

  tags = {
    "Name" = "private-subnet"
  }
}

resource "aws_subnet" "terra_public_subnet" { # Custom Public Subnet
  count             = length(var.public_subnet)
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = var.public_subnet[count.index]
  availability_zone = var.availability_zone[count.index % length(var.availability_zone)]

  tags = {
    "Name" = "public-subnet"
  }
}

resource "aws_internet_gateway" "terra_ig" { # Custom Internet Gateway
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    "Name" = "Customr IG"
  }
}

resource "aws_route_table" "terra_public" { # Custom Public-facing Route Table
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_ig.id
  }

  tags = {
    "Name" = "Custom Public-facing"
  }
}

resource "aws_route_table_association" "terra_public_association" { # Assign Route table -> Public Subnet
  for_each       = { for k, v in aws_subnet.terra_public_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.terra_public.id
}

resource "aws_eip" "terra_nat_ip" { # Custom NAT Gateway need E-IP
  vpc = true
}

resource "aws_nat_gateway" "terra_nat_gateway" { # Custom Public-facing NAT Gateway
  depends_on = [aws_internet_gateway.terra_ig]

  allocation_id = aws_eip.terra_nat_ip.id
  subnet_id     = aws_subnet.terra_public_subnet[0].id

  tags = {
    Name = "Custom Public NAT Gateway"
  }
}

resource "aws_route_table" "terra_private" { # Custom Private-facing Route Table
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.terra_nat_gateway.id
  }

  tags = {
    "Name" = "Custom Private-facing"
  }
}

resource "aws_route_table_association" "terra_public_private" {
  for_each       = { for k, v in aws_subnet.terra_private_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.terra_private.id
}
