resource "aws_vpc" "vpc" {
  cidr_block       = var.cidrBlock
  instance_tenancy = "default"

  tags = {
    Name = "${var.ProjectName}-vpc"
  }
}

resource "aws_internet_gateway" "internetGateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.ProjectName}-IGW"
  }

}

data "aws_availability_zones" "zones" {
  state = "available"
}
output "zones" {
  value = data.aws_availability_zones.zones.names
}

# create public subnet az1

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.zones.names[count.index]
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name" = "Public-Subnet-${count.index + 1}"
  }
}



# create route table and public route i.e. add internet gateway in public route table with internet access 0.0.0.0/0
# we create public route for internet access

resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetGateway.id
  }
}

# associate public subnet 1 to public route table

resource "aws_route_table_association" "publicSubnetRoute" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.publicRouteTable.id
}



# create private subnet

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 2) # start from 10.0.2.0/24
  availability_zone = data.aws_availability_zones.zones.names[count.index]

  tags = {
    Name = "Private-Subnet-${count.index + 1}"
    Type = "private"
  }
}


# create private route table
resource "aws_route_table" "privateRouteTable" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Private-Route-Table"
  }
}

# associate private subnet route to private route table
resource "aws_route_table_association" "privateSubnetRoute" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.privateRouteTable.id
}



# create nat-gateway
# resource "aws_eip" "elasticIP" {}

# resource "aws_nat_gateway" "natGateway" {
#   allocation_id = aws_eip.elasticIP.id
#   subnet_id     = aws_subnet.public[0].id
#   tags = {
#     Name = "NAT-Gateway"
#   }
# }

# ## ensure route
# resource "aws_route" "natGatewayRoute" {
#   route_table_id         = aws_route_table.privateRouteTable.id
#   nat_gateway_id         = aws_nat_gateway.natGateway.id
#   destination_cidr_block = "0.0.0.0/0"
# }