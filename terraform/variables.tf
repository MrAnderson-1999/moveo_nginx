variable "ami_id" {
  description = "AMI ID for the instances"
  default     = "ami-0fc5d935ebf8bc3bc"
}

variable "instance_type_bastion" {
  description = "Instance type for the bastion host"
  default     = "t2.micro"
}

variable "existing_zone_id" {
  description = "The zone id of the already existing zone"
  default     = "Z0283867TKPLYDB766JW"
}

variable "domain_name" {
  description = "The domain name url of the desired A record"
  default     = "humanity-project.com"
}

variable "instance_type_private" {
  description = "Instance type for the private instance"
  default     = "t2.medium"
}

variable "key_name" {
  description = "Key pair name"
  default     = "moveo-pair"
}

variable "provider_region" {
  description = "The main region of the VPC"
  default     = "us-east-1"
}













variable "user_data_script" {
  description = "User data script for private instance initialization"
  default     = <<-EOF
  #!/bin/bash
  exec > /home/ubuntu/init.log 2>&1  # Redirect stdout and stderr to init.log
  GREEN='\033[1;32m'
  RED='\033[0;91m'
  OFF='\033[0m'

  echo -e "$${GREEN}Cloud Init Script started$${OFF}\n";
  cd /home/ubuntu/
  # Clone your project repository
  if [ -d "moveo_nginx" ]; then
      echo -e "$${GREEN}---REPO ALREADY EXISTS---$${OFF}\n";
  else
      echo -e "$${GREEN}---REPO CLONE STARTED---$${OFF}\n";
      if git clone https://github.com/MrAnderson-1999/moveo_nginx.git; then
          echo -e "$${GREEN}####################$${OFF}";
          echo -e "$${GREEN}Cloning repo finished$${OFF}";
          echo -e "$${GREEN}####################$${OFF}\n";
      else
          echo -e "$${RED}---REPO CLONE FAILED---$${OFF}\n";
          exit 1;
      fi
  fi
  
  cd moveo_nginx || exit

  echo -e "$${GREEN}---INSTALL MICROK8S---$${OFF}\n";
  apt update && apt install snapd -y
  snap install microk8s --classic
  usermod -a -G microk8s ubuntu
  microk8s enable dns
  microk8s enable ingress
  microk8s enable dashboard
  microk8s kubectl cluster-info
  microk8s kubectl apply -f kubernetes/nginx.yaml
  microk8s kubectl cluster-info
  microk8s kubectl get all
  echo -e "$${GREEN}---SCRIPT FINISHED---$${OFF}\n";
  EOF
}
