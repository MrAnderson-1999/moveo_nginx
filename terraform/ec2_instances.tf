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