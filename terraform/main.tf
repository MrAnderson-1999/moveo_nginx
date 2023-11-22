terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
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

# Create a Public Subnet
resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "moveo-public-subnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "my_private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"

  tags = {
    Name = "moveo-private-subnet"
  }
}

# Security Group for Bastion Host SSH access
resource "aws_security_group" "bastion_ssh_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Ingress rule for SSH access from anywhere
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # IP whitelist POOL
  }

  # Outbound rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "moveo-bastion-ssh-security-group"
  }
}


# Security Group for SSH access
resource "aws_security_group" "my_ssh_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow SSH access from the Bastion Host
  ingress {
    description     = "SSH from Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_ssh_sg.id]
  }

  # Outbound rule to allow all outbound traffic to the internet via the NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "moveo-ssh-security-group"
  }
}

# Security Group for HTTP access
resource "aws_security_group" "my_http_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule to allow all outbound traffic to the internet via the NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "moveo-http-security-group"
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

# EC2 Instance in the Private Subnet
resource "aws_instance" "my_instance" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_private_subnet.id
  vpc_security_group_ids = [aws_security_group.my_ssh_sg.id, aws_security_group.my_http_sg.id]
  key_name               = "moveo-kp"

  tags = {
    Name = "moveo-instance"
  }
}


# Create a Bastion Host in the Public Subnet
resource "aws_instance" "bastion" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_public_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion_ssh_sg.id]
  key_name      = "moveo-kp"    

  tags = {
    Name = "moveo-bastion"
  }

}

# Output the public IP of the Bastion Host
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

# Output the public IP of the EC2 Instance in the Private Subnet
output "private_instance_ip" {
  value = aws_instance.my_instance.private_ip
}