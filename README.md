# One command - Full AWS Nginx Infrastructure Deployment using Terraform and Kubernetes

## Overview
Deploy a robust, secure AWS infrastructure and manage with Terraform using only ```terraform apply```, featuring an Nginx pod deployment in a single-node Microk8s private subnet EC2. Accessible through a custom DNS name linked to an Application Load Balancer (ALB) using HTTPS, the setup also includes a Bastion host for secure private subnet access and cluster managment. 
![image](https://github.com/MrAnderson-1999/moveo_nginx/assets/87763298/3f781ec6-e52f-43ee-bfe8-d1461126d944)




## Key Infrastructure Components
- **VPC**: Includes both public and private subnets.
- **EC2 Instances**: 
   - Bastion host in public subnet for secure access.
   - Private Nginx server in a private subnet.
- **Application Load Balancer (ALB)**: Directs HTTP traffic to the Nginx server.
- **Route 53**: Manages DNS for ALB.
- **Security Measures**: Security Groups and Network ACLs to regulate traffic flow.

## Repository Structure
- ```main.tf```: Core Terraform configuration, VPC, Subnets, Route tables and assosiations, NAT and Elastic ip
- ```variables.tf```: Definitions for readability  and customization.
- ```outputs.tf```: Displays key information post-deployment.
- ```security_groups.tf```: Defines security rules.
- ```ec2_instances.tf```: EC2 instance setups.
- ```alb.tf```: Application Load Balancer settings.
- ```route53.tf```: DNS settings for Route 53.And certs handling


## Prerequisites
- AWS Account with appropriate permissions.
- Terraform (version 1.2.0 or later).
- Route53 registered domain name AND its attached hosted zone


# Getting Started
### Clone git repo
- ```git clone https://github.com/MrAnderson-1999/moveo_nginx.git```

### Set AWS environment
- Create or use an existing AWS key-pair : **Must be set on the same region configured at```provider_region``` in variable.tf**
- Save the key-pair .pem file on local pc.
- Adjust the key-par name variable ```key_name``` in the variable.tf file to match the name of yours
- Set the AWS credentials of the user owner of the key pair as environmental variables on local pc : **Only of a user with an 'Administrator' privilage**
   - ```export AWS_ACCESS_KEY_ID="<Access ID>"```
   - ```export AWS_SECRET_ACCESS_KEY="<Access SECRET>"```
  
### Modify existing_zone_id AND domain_name
- Make sure you have domain name and a hosted zone already bought and setup on route 53
- Adjust accordingle the following variable from the ```variables.tf``` file
```variable "existing_zone_id" {
  description = "The zone id of the already existing hosted zone"
  default     = "Z0283867TKPLYDB766JW"
}

variable "domain_name" {
  description = "The domain name url which attached to the hosted zone"
  default     = "humanity-project.com"
}
```

### Initiate Terraform Workflow
- ```cd moveo-nginx/terraform```
- Initialize Terraform, ```terraform init```
- Review the Terraform Plan, ```terraform plan```
- Apply the Terraform Configuration, ```terraform apply```
- Look out for useful output logs variables after ```terraform apply``` finish. includes the bastion public ip and the kubernetes cluster private ip etc .
- The whole Iac may take up to 5 minutes to be fully functional. When it does, you will see **'yo this is nginx'** text when entering the ```domain_name``` URL.

# Uses and Customization

### Access and Management

**One-time Setup of SSH from Bastion to Kubernetes cluster**
- Run on local pc : ```scp -i ~/.ssh/local_key.pem local_key.pem ubuntu@[BASTION_PUBLIC_IP]:```

**SSH to Bastion Host**
- Run on local pc ```ssh -i "local_key.pem" ubuntu@[BASTION_PUBLIC_IP]```

**SSH to Cluster Server And Manage**
- Run on Bastion : ```ssh -i "local_key.pem" [PRIVATE_INSTANCE_IP]```
- Run on Cluster : ```microk8s kubectl get all / <any other command to the kubernetes server>```

### Additional customization using ```variables.tf```
- ```instance_type_bastion``` : Define Bastion machine size type | **Default is t2.micro**
- ```instance_type_private```: Define Cluster machine size type | **Minimum and default is t2.medium**  
- ```existing_zone_id```,```domain_name``` : Route 53 DNS settings.
- ```key_name``` : Your AWS SSH key pair. will be used for also Bastion and the Cluster
- ```user_data_script``` : Bootstrapping script for the Nginx server.
-  ```provider_region``` : Main VPC region that will be used for this Iac


### Terraform Outputs
After running terraform apply, you'll receive these key outputs:

- ```private_instance_ip``` : The private ip of the kubernetes Cluster, which on the private subnet. Used for ssh from Bastion to Cluster.
- ```bastion_public_ip``` : The Bastion Public ip, from there you could ssh to the Cluster.
- ```nat_gateway_ip``` : NAT Gateway Public IP, the internet access from the private subnet.
- ```alb_dns_name``` : ALB Public DNS Name which used as the A record to the cluster.

### Cleanup
- To destroy the AWS resources run ```terraform destroy```

# Trouble shooting
**Terraform apply wen fine, but cant see website after more then 5 minutes**
- Verify the healtcheck is fine and traffic routed to pod : AWS target group health check via AWS UI
- Verify the pod is running on the cluster : SSH the cluster via Bastion and verify its running the ngnix pod via ```microk8s kubectl get all```
- Verify its not the user_data script : ```cat init.log``` to se if the initial installation and setup of the cluster were successful

**Got error of credentials when run ```terraform plan/apply```**
- Verify youve exported the ```AWS_ACCESS_KEY_ID``` AND ```AWS_SECRET_ACCESS_KEY``` correctly by running ```echo $AWS_ACCESS_KEY_ID```,```echo $AWS_SECRET_ACCESS_KEY``` on local pc. And so this credentials are of a Administrator level privelage aws user which the key-pair created by him.


## Assignment Submission
1. **Application URL**: [https://humanity-project.com](http://humanity-project.com)
2. **GitHub Repository**: [GitHub Repository URL](https://github.com/MrAnderson-1999/moveo_nginx)
---

## Sources
ACL's and Security groups levels: https://www.linkedin.com/pulse/connecting-internet-from-ec2-instance-private-subnet-aws-thandra/
