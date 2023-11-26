terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "remote" {
    organization = "moveo-nginx"

    workspaces {
      name = "moveo_nginx"
    }
  }
}

provider "aws" {
  region = var.provider_region
}





# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "moveo-vpc"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "moveo-igw"
  }
}


data "aws_availability_zones" "available" {
  state = "available"
}


# Create a Public Subnet
resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]  
  map_public_ip_on_launch = true

  tags = {
    Name = "moveo-public-subnet"
  }
}

# Create a Public Subnet
resource "aws_subnet" "my_public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]  
  map_public_ip_on_launch = true

  tags = {
    Name = "moveo-public-subnet-2"
  }
}

# Create a Private Subnet
resource "aws_subnet" "my_private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]  

  tags = {
    Name = "moveo-private-subnet"
  }
}







# Elastic IP for the NAT Gateway
resource "aws_eip" "my_eip" {
  vpc = true

  tags = {
    Name = "moveo-eip"
  }
}


# Create a NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.my_public_subnet.id

  tags = {
    Name = "moveo-nat-gateway"
  }
}









# Route Table for the Private Subnet
resource "aws_route_table" "private_subnet_route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  tags = {
    Name = "moveo-private-subnet-route"
  }
}

# Associate the Private Subnet with the Route Table
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.my_private_subnet.id
  route_table_id = aws_route_table.private_subnet_route.id
}

# Create a Route Table for the Public Subnet
resource "aws_route_table" "public_subnet_route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "moveo-public-subnet-route"
  }
}

# Associate the Public Subnet with the Route Table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.public_subnet_route.id
}