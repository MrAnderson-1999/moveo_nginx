# Project Documentation

## Overview
This project sets up an AWS infrastructure using Terraform, which includes an Application Load Balancer (ALB) routing traffic to an Nginx server running on an EC2 instance within a private subnet, accessible via a bastion host for SSH connectivity. The infrastructure also includes Route 53 for domain name routing to the ALB.

## Architecture
Provide a deployment diagram here (if available).

## Prerequisites
- AWS Account
- Terraform installed
- SSH key pair for EC2 instances

## Setup and Deployment
1. **Initialize Terraform**: Run `terraform init` in the project directory to initialize Terraform, which will download necessary providers.

2. **Plan Terraform Execution**: Execute `terraform plan` to review the changes that will be made to your AWS infrastructure.

3. **Apply Configuration**: Run `terraform apply` to apply the configuration. Confirm the action when prompted.

4. **Accessing the Application**: 
   - After successful deployment, use the output `alb_dns_name` to access the Nginx server via the browser or `curl`.
   - For SSH access to the private instance, first SSH into the bastion host using its public IP (`bastion_public_ip` output), then SSH into the private instance using its private IP (`private_instance_ip` output).

## File Structure
- `vpc.tf`: Contains VPC and subnet configurations.
- `security_groups.tf`: Security group definitions.
- `ec2_instances.tf`: EC2 instance configurations for the Nginx server and bastion host.
- `alb.tf`: ALB, target group, and listener configurations.
- `route53.tf`: Route 53 configurations for domain name routing.
- `variables.tf`: Definitions of variables used in configurations.
- `outputs.tf`: Output values like ALB DNS name and instance IPs.

## Destroying Infrastructure
To remove all AWS resources created by this Terraform configuration, run `terraform destroy` and confirm the action.

## Additional Notes
- Ensure your AWS credentials are set up correctly, either via the AWS CLI or environment variables.
- Modify variables in `variables.tf` as needed to fit your requirements.

## Support
For support, please contact [support email/contact].
