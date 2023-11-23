# AWS Nginx Infrastructure Deployment using Terraform

## Overview
This project utilizes Terraform to deploy a secure and scalable AWS infrastructure. It features an Nginx server in a private subnet, accessible via a custom DNS name through an Application Load Balancer (ALB). A Bastion host is implemented for secure SSH access to the private subnet.
![image](https://github.com/MrAnderson-1999/moveo_nginx/assets/87763298/1c45f7b9-b25e-4e73-85b0-5f692f61140e)



## Submission Links
1. **Application URL**: [http://humanity-project.com](http://humanity-project.com)
2. **GitHub Repository**: [GitHub Repository URL](https://github.com/MrAnderson-1999/moveo_nginx)

## Infrastructure Components
- **VPC**: Configured with public and private subnets.
- **EC2 Instances**: Bastion host in the public subnet; Nginx server in the private subnet.
- **Application Load Balancer (ALB)**: Routes HTTP traffic to the Nginx server.
- **Route 53**: Manages the custom DNS name for the ALB.
- **Security Groups and Network ACLs**: Ensure secure network traffic.

## Prerequisites
- An active AWS Account.
- Terraform v1.2.0 or later.
- An SSH key pair registered with AWS.

## Customization via Terraform Variables
The `variables.tf` file allows for tailoring the deployment. Key variables:
- `ami_id`, `instance_type_bastion`, `instance_type_private`: AMI and instance types.
- `existing_zone_id`, `domain_name`: Route 53 configurations.
- `key_name`: SSH key pair.
- `user_data_script`: Script for setting up the Nginx server.

## Repository Structure
- `main.tf`: Primary Terraform configuration.
- `variables.tf`: Variables for customization.
- `outputs.tf`: Outputs of the Terraform deployment.
- `vpc.tf`: Configuration for VPC and subnets.
- `security_groups.tf`: Security group rules.
- `ec2_instances.tf`: EC2 instances setup.
- `alb.tf`: ALB setup and configurations.
- `route53.tf`: Route 53 DNS configurations.



- ## Deployment Instructions
**Clone git**

**Initialize Terraform**:
   ```terraform init```


**Export AWS env**
**Create/Use key-pair**
- adjust the key-pair at the variables.tf

1. **Initialize Terraform**
   ```terraform init```
2. **Review Plan**
   ```terraform plan```
3. **Apply Configuration**
   ```terraform apply```

**Accessing the Application**
Web Application URL: Access the Nginx server via http://[ALB_DNS_NAME] provided in the Terraform output.
SSH Access:
SSH into Bastion Host: ssh -i "path_to_key" ubuntu@[BASTION_PUBLIC_IP].
From Bastion, SSH into the private instance: ssh -i "path_to_key" ubuntu@[PRIVATE_INSTANCE_IP].
Cleanup
To destroy the AWS resources created by this Terraform configuration:


when terraform apply ran, it returns 4 relevant outputs:

Output the public IP of the Bastion Host
-
- first setup bastion by scp your local .pem file to the bastion: ```scp -i ~/.ssh/key-pair-name.pem``` ( make sure youve exported your admin level user cred. AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY) 
- ssh to bastion

Output the private IP of the EC2 Instance
-
- after setting the bastion, you would be able to ssh the private ip of the nginx from the bastion using the .pem file

Output the public IP of the NAT Gateway
-

Output the DNS name of the ALB to access the Nginx server
-


shell
Copy code
terraform destroy
Support
For queries or support related to this infrastructure, please contact [Your Email/Contact Information].

Submission URLs
Web Application: [Web Application URL]
GitHub Repository: [GitHub Repository URL]
Please replace [Web Application URL], [GitHub Repository URL], [BASTION_PUBLIC_IP], and [PRIVATE_INSTANCE_IP] with actual values from your Terraform output and GitHub repository.

python
Copy code

### Notes for Submission:
- Make sure to include the actual URLs where indicated in the 'Submission URLs' section.
- Review and test all steps in the 'Deployment Instructions' to ensure they work as intended.
- Customize the 'Support' section with your contact information or relevant details.
- Add any additional instructions or notes that might be helpful for the HR manager or other reviewers.



