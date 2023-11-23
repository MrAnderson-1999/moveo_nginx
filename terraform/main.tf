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

# Create a Public Subnet
resource "aws_subnet" "my_public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"  
  map_public_ip_on_launch = true

  tags = {
    Name = "moveo-public-subnet-2"
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
  # Outbound rule to allow all outbound traffic to the internet
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


# Security Group for private instance
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

  tags = {
    Name = "moveo-ssh-security-group"
  }
}

# Security Group for private instance HTTP access
resource "aws_security_group" "my_http_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Additional egress rule for HTTP traffic
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTP traffic"
  }

  # Allow inbound traffic from ALB on HTTP port
  ingress {
    description      = "HTTP from ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_sg.id]
  }

  # Outbound rule to allow all outbound traffic to the internet via NAT
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







# Application Load Balancer (ALB) Resource
resource "aws_lb" "my_alb" {
  name               = "moveo-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.my_public_subnet.id,aws_subnet.my_public_subnet_2.id] # Use public subnet ID
  security_groups    = [aws_security_group.alb_sg.id]


  tags = {
    Name = "moveo-application-load-balancer"
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.my_vpc.id

  # Ingress traffic on HTTP and HTTPS
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "moveo-alb-security-group"
  }
}

# Target Group for EC2 Instances
resource "aws_lb_target_group" "my_tg" {
  name     = "moveo-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "moveo-target-group"
  }
}

# Listener for ALB
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

# Register EC2 Instances with Target Group
resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.my_instance.id
  port             = 80
}












# Public Subnet NACL
resource "aws_network_acl" "public-acl" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow inbound HTTP traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Inbound SSH - allow traffic on port 22
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }


  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound HTTP and HTTPS traffic
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Outbound rules for allowing traffic to the internet
  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow inbound and outbound traffic for Ephemeral Ports
  # Adjust the rule numbers if necessary
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "moveo-public-acl"
  }
}


resource "aws_network_acl_association" "public_acl_association" {
  network_acl_id = aws_network_acl.public-acl.id
  subnet_id      = aws_subnet.my_public_subnet.id
}
resource "aws_network_acl_association" "public_2_acl_association" {
  network_acl_id = aws_network_acl.public-acl.id
  subnet_id      = aws_subnet.my_public_subnet_2.id
}

# Private Subnet NACL
resource "aws_network_acl" "private-acl" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow inbound SSH from Bastion's Security Group
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 22
    to_port    = 22
  }

  # Allow outbound HTTP and HTTPS traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound responses (Ephemeral Ports)
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow outbound HTTP and HTTPS traffic
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound traffic for Ephemeral Ports
  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "moveo-private-acl"
  }
}


resource "aws_network_acl_association" "private_acl_association" {
  network_acl_id = aws_network_acl.private-acl.id
  subnet_id      = aws_subnet.my_private_subnet.id
}






# Fetch the existing hosted zone details
data "aws_route53_zone" "existing_zone" {
  name = "humanity-project.com"
}

# Create a DNS record for the root domain (humanity-project.com) pointing to the ALB
resource "aws_route53_record" "root_record" {
  zone_id = data.aws_route53_zone.existing_zone.zone_id
  name    = "humanity-project.com"
  type    = "A"

  alias {
    name                   = aws_lb.my_alb.dns_name
    zone_id                = aws_lb.my_alb.zone_id
    evaluate_target_health = true
  }
}




# Instances
resource "aws_instance" "my_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_private
  subnet_id              = aws_subnet.my_private_subnet.id
  vpc_security_group_ids = [aws_security_group.my_ssh_sg.id, aws_security_group.my_http_sg.id]
  key_name               = var.key_name
  user_data              = var.user_data_script
  tags = {
    Name = "moveo-private-instance"
  }
}

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_bastion
  subnet_id              = aws_subnet.my_public_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion_ssh_sg.id]
  key_name               = var.key_name
  tags = {
    Name = "moveo-bastion-instance"
  }
}

# Output the public IP of the Bastion Host
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

# Output the private IP of the EC2 Instance
output "private_instance_ip" {
  value = aws_instance.my_instance.private_ip
}

# Output the public IP of the NAT Gateway
output "nat_gateway_ip" {
  value = aws_nat_gateway.my_nat_gateway.public_ip
}

# Output the DNS name of the ALB to access the Nginx server
output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}