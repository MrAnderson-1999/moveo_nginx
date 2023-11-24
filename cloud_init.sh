#!/bin/bash
GREEN='\033[1;32m'
RED='\033[0;91m'
OFF='\033[0m'

echo -e "${GREEN}Cloud Init Script started${OFF}\n";
sudo apt-get update; sudo apt-get upgrade;
# Clone your project repository
if [ -d "moveo_nginx" ]; then
    echo -e "${GREEN}---REPO ALREADY EXISTS---${OFF}\n";
else
    # Clone your project repository
    echo -e "${GREEN}---REPO CLONE STARTED---${OFF}\n";
    if git clone https://github.com/MrAnderson-1999/moveo_nginx.git; then
        echo -e "${GREEN}####################${OFF}";
        echo -e "${GREEN}Cloning repo finished${OFF}";
        echo -e "${GREEN}####################${OFF}\n";
    else
        echo -e "${RED}---REPO CLONE FAILED---${OFF}\n";
        exit 1; # Exit the script if repo cloning fails.
    fi
fi

# Docker installation
# Check if Docker is already installed
if ! command -v docker &> /dev/null; then
    # Docker is not installed, so install it
    echo -e "${GREEN}---DOCKER INSTALATION STARTED---${OFF}\n";
    if /bin/bash -c "$(curl -fsSL https://git.io/JDGfm)"; then
        echo -e "${GREEN}####################${OFF}";
        echo -e "${GREEN}Finished installing Docker${OFF}";
        echo -e "${GREEN}####################${OFF}\n";

        # Add ec2-user to the docker group (change ec2-user to ubuntu for Ubuntu AMIs)
        sudo usermod -aG docker ubuntu

        # Apply group changes in a new shell instance for ec2-user
        sudo -u ubuntu sg docker -c "/bin/bash -c 'docker -v'"

    else
        echo -e "${RED}---DOCKER INSTALATION FAILED---${OFF}\n";
        exit 1; # Exit the script if Docker installation fails.
    fi
else
    echo -e "${GREEN}---DOCKER IS ALREADY INSTALLED---${OFF}\n";
fi

# Move into your project directory
cd moveo_nginx || exit

# Build Docker images from your Docker Compose file
echo -e "${GREEN}---BUILD IMAGE STARTED---${OFF}\n";
if docker build -t moveo-nginx -f nginx/Dockerfile nginx/; then
    echo -e "${GREEN}####################${OFF}";
    echo -e "${GREEN}Finished Building${OFF}";
    echo -e "${GREEN}####################${OFF}\n";
else
    echo -e "${RED}---BUILD IMAGE FAILED---${OFF}\n";
    exit 1; # Exit the script if Docker build fails.
fi
sleep 2
echo -e "${GREEN}---INIT IMAGE STARTED---${OFF}\n";
if docker run --name nginx-container -p 80:80 -d moveo-nginx; then
    echo -e "${GREEN}####################${OFF}";
    echo -e "${GREEN}Finished Initializing${OFF}";
    echo -e "${GREEN}####################${OFF}\n";
else
    echo -e "${RED}Failed Initializing${OFF}\n";
    exit 1; # Exit the script if image initialization fails.
fi

echo -e "${GREEN}---INSTALL MICROK8S---${OFF}\n";
sudo apt update && sudo apt install snapd -y
sudo snap install microk8s --classic
sudo usermod -a -G microk8s ubuntu
sudo chown -f -R ubuntu ~/.kube
sudo microk8s enable dns
sudo microk8s enable ingress
sudo microk8s enable dashboard


echo -e "${GREEN}---SCRIPT FINISHED---${OFF}\n";
