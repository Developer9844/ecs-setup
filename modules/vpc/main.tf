resource "aws_vpc" "my-vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "${var.project_name}-igw"
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
  vpc_id                  = aws_vpc.my-vpc.id
  availability_zone       = data.aws_availability_zones.zones.names[count.index]
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-subnet-${count.index + 1}"
  }
}



# create route table and public route i.e. add internet gateway in public route table with internet access 0.0.0.0/0
# we create public route for internet access

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

# associate public subnet 1 to public route table

resource "aws_route_table_association" "public_subnet_route" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-rt.id
}



# create private subnet

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 2) # start from 10.0.2.0/24
  availability_zone = data.aws_availability_zones.zones.names[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
    Type = "private"
  }
}


# create private route table
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "private-route-table"
  }
}

# associate private subnet route to private route table
resource "aws_route_table_association" "private_subnet_route" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-rt.id
}



# create nat-gateway
resource "aws_eip" "elastic_ip" {}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "nat_gateway"
  }
}

## ensure route
resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_route_table.private-rt.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}
