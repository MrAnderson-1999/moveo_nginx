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
  port     = 30007 # kubernetes service port, needs to be the NodePort
  protocol = "HTTP" # Ngnix runnin http
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP" # Ngnix runnin http
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "moveo-target-group"
  }
}

# Listener for ALB redirects to HTTPS
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener for ALB HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.my_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}


# Register EC2 Instances with Target Group
resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.my_instance.id
  port             = 30007 # NodePort
}