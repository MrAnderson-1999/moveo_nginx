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