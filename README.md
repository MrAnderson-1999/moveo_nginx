# One command - Full AWS Nginx Infrastructure Deployment using Terraform

## Overview
Deploy a robust, secure AWS infrastructure with Terraform, featuring an Nginx server in a private subnet. Accessible through a custom DNS name linked to an Application Load Balancer (ALB), the setup also includes a Bastion host for secure private subnet access. 
![image](https://github.com/MrAnderson-1999/moveo_nginx/assets/87763298/6b260e31-ec4e-4e10-bd57-fe972d1bd65c)



## Key Infrastructure Components
- **VPC**: Includes both public and private subnets.
- **EC2 Instances**: 
   - Bastion host in public subnet for secure access.
   - Private Nginx server in a private subnet.
- **Application Load Balancer (ALB)**: Directs HTTP traffic to the Nginx server.
- **Route 53**: Manages DNS for ALB.
- **Security Measures**: Security Groups and Network ACLs to regulate traffic flow.

## Repository Structure
- `main.tf`: Core Terraform configuration.
- `variables.tf`: Definitions for customization.
- `outputs.tf`: Displays key information post-deployment.
- `vpc.tf`: VPC and subnet configurations.
- `security_groups.tf`: Defines security rules.
- `ec2_instances.tf`: EC2 instance setups.
- `alb.tf`: Application Load Balancer settings.
- `route53.tf`: DNS settings for Route 53.


## Prerequisites
- AWS Account with appropriate permissions.
- Terraform (version 1.2.0 or later).
- SSH key pair registered in AWS.
- Registered domain name AND attached hosted zone

## Deployment Instructions
**Clone git**
- ```git clone https://github.com/MrAnderson-1999/moveo_nginx.git```

**Set AWS environment**
- Create or use an existing AWS key-pair.
- Save the key-pair .pem file.
- Adjust the key-par name variable "key_name" in the variable.tf file
- Set AWS credentials env:
   - ```export AWS_ACCESS_KEY_ID="<Access ID>"```
   - ```export AWS_SECRET_ACCESS_KEY="<Access SECRET>"```
   - 
**Modify existing_zone_id AND domain_name variables.tf**
```variable "existing_zone_id" {
  description = "The zone id of the already existing zone"
  default     = "Z0283867TKPLYDB766JW"
}

variable "domain_name" {
  description = "The domain name url of the desired A record"
  default     = "humanity-project.com"
}
```

**Terraform Workflow**
- Initialize Terraform: ```terraform init```
- Review the Terraform Plan: ```terraform plan```
- Apply the Terraform Configuration: ```terraform apply```

## Access and Management
- **SSH to Bastion Host:**
   - ```ssh -i "local_key.pem" ubuntu@[BASTION_PUBLIC_IP]```
- **One-time Setup of SSH from Bastion to Nginx:**
   - ```scp -i ~/.ssh/local_key.pem local_key.pem ubuntu@[BASTION_PUBLIC_IP]:```
- **SSH to Nginx Server:**
   - From Bastion run
     - ```ssh -i "local_key.pem" [PRIVATE_INSTANCE_IP]```

## Customizing With Terraform
**Modify `variables.tf` to suit specific needs. Important** variables include:
- `ami_id`, `instance_type_bastion`, `instance_type_private`: Define EC2 settings.
- `existing_zone_id`, `domain_name`: Route 53 DNS settings.
- `key_name`: Your AWS SSH key pair.
- `user_data_script`: Bootstrapping script for the Nginx server.


**Terraform Outputs**
After running terraform apply, you'll receive these key outputs:

- Bastion Host Public IP: For setting up Bastion SSH access.
- Private Instance Private IP: For SSH access from the Bastion Host.
- NAT Gateway Public IP: For internet access from the private subnet.
- ALB DNS Name: To access the Nginx server.

**Cleanup**
- To destroy the AWS resources:```terraform destroy```

## Submission Links
1. **Application URL**: [https://humanity-project.com](http://humanity-project.com)
2. **GitHub Repository**: [GitHub Repository URL](https://github.com/MrAnderson-1999/moveo_nginx)
---

## Sources
ACL's and Security groups levels: https://www.linkedin.com/pulse/connecting-internet-from-ec2-instance-private-subnet-aws-thandra/
