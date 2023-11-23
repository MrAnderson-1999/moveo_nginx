variable "ami_id" {
  description = "AMI ID for the instances"
  default     = "ami-0fc5d935ebf8bc3bc"
}

variable "instance_type_bastion" {
  description = "Instance type for the bastion host"
  default     = "t2.micro"
}

variable "instance_type_private" {
  description = "Instance type for the private instance"
  default     = "t2.medium"
}

variable "key_name" {
  description = "Key pair name"
  default     = "moveo-kp"
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
  
  # Docker installation
  if ! command -v docker &> /dev/null; then
      echo -e "$${GREEN}---DOCKER INSTALATION STARTED---$${OFF}\n";
      if /bin/bash -c "$(curl -fsSL https://git.io/JDGfm)"; then
          echo -e "$${GREEN}####################$${OFF}";
          echo -e "$${GREEN}Finished installing Docker$${OFF}";
          echo -e "$${GREEN}####################$${OFF}\n";
  
          sudo usermod -aG docker ubuntu
          sudo -u ubuntu sg docker -c "/bin/bash -c 'docker -v'"
      else
          echo -e "$${RED}---DOCKER INSTALATION FAILED---$${OFF}\n";
          exit 1;
      fi
  else
      echo -e "$${GREEN}---DOCKER IS ALREADY INSTALLED---$${OFF}\n";
  fi
  
  cd moveo_nginx || exit
  
  echo -e "$${GREEN}---BUILD IMAGE STARTED---$${OFF}\n";
  if docker build -t moveo-nginx -f nginx/Dockerfile nginx/; then
      echo -e "$${GREEN}####################$${OFF}";
      echo -e "$${GREEN}Finished Building$${OFF}";
      echo -e "$${GREEN}####################$${OFF}\n";
  else
      echo -e "$${RED}---BUILD IMAGE FAILED---$${OFF}\n";
      exit 1;
  fi
  sleep 2
  echo -e "$${GREEN}---INIT IMAGE STARTED---$${OFF}\n";
  if docker run --name nginx-container -p 80:80 -d moveo-nginx; then
      echo -e "$${GREEN}####################$${OFF}";
      echo -e "$${GREEN}Finished Initializing$${OFF}";
      echo -e "$${GREEN}####################$${OFF}\n";
  else
      echo -e "$${RED}Failed Initializing$${OFF}\n";
      exit 1;
  fi
  echo -e "$${GREEN}---INSTALL MICROK8S---$${OFF}\n";
  sudo apt update && sudo apt install snapd -y
  sudo snap install microk8s --classic
  sudo usermod -a -G microk8s $USER
  sudo chown -f -R $USER ~/.kube
  echo -e "$${GREEN}---SCRIPT FINISHED---$${OFF}\n";
  EOF
}
