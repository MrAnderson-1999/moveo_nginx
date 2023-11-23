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