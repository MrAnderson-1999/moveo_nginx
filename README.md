#    ONE COMMAND - Basic Kubernetes Production Infrastructure Via Terraform - Deploy Nginx POD

## Overview
Deploy a robust and secure AWS infrastructure with Terraform by only using ```terraform apply```. featuring an Nginx pod deployment in a single-node Microk8s cluster within a private subnet EC2. Accessible through a custom DNS name linked to an Application Load Balancer (ALB) using HTTPS. the setup also includes a Bastion host for secure and restricted private subnet access and cluster managment. 
![image](https://github.com/MrAnderson-1999/moveo_nginx/assets/87763298/a54aa754-c805-478e-9345-b293d887e619)





## Infrastructure Components and Featuers
- **VPC**: Includes both public and private subnets.
- **EC2 Instances**: 
   - Bastion host in public subnet for secure access.
   - Private Nginx server in a private subnet.
- **Application Load Balancer (ALB)**: Directs HTTP traffic to the Nginx server.
- **Route 53**: Manages DNS for ALB.
- **Security Measures**: Security Groups and Network ACLs to regulate traffic flow.
- **Automates the Microk8s Single noded Cluster setup**:```user_data``` script initiated when cluster ec2 start. it cloning the repo, download and install microk8s, run deployment  ```nginx.yaml``` 
- **Bastion**: The Cluster is configured to be sshable only from the Bastion using the same key-pair as for the Bastion
- **NAT**: The Iac deploys Kubernetes cluster on a private subnet, it (and the kubernetes server API) can access internet using NAT
- **Kube Deployment**: The cluster deploys an Nginx port 80 deployment on itself, and get exposed from the instance via NodePort 30007
- **A record provisioning**: An A record is created and ponited to the ALB public dns, which listens on port 80/443 and forward traffic to the Cluster instance as HTTP on port 30007
![image](https://github.com/MrAnderson-1999/moveo_nginx/assets/87763298/a88a9895-8154-453b-94f2-2dc66216664c)









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
 
### Remove / Adjust the remote backend at the head of ```main.tf``` 
```
  backend "remote" {
    organization = "moveo-nginx"

    workspaces {
      name = "moveo_nginx"
    }
  }
```

### Modify ```existing_zone_id``` AND ```domain_name```
- Make sure you have domain name and a hosted zone already bought and setup on route 53
- Adjust accordingle the following variables at the ```variables.tf``` file
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
![image](https://github.com/MrAnderson-1999/moveo_nginx/assets/87763298/acb3fe89-e8ba-49f0-9917-86bf433b4b06)


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
- ```existing_zone_id```,```domain_name``` : Route 53 DNS settings
- ```key_name``` : Your AWS SSH key pair. will be used for also Bastion and the Cluster
- ```user_data_script``` : Bootstrapping script for the Cluster setup and pod deployment
-  ```provider_region``` : Main VPC region that will be used for this Iac


### Terraform Outputs
After running terraform apply, you'll receive these key outputs:

- ```private_instance_ip``` : The private ip of the kubernetes Cluster, which on the private subnet.
- ```bastion_public_ip``` : The Bastion Public ip, from there you could ssh to the Cluster using ```private_instance_ip```.
- ```nat_gateway_ip``` : NAT Gateway Public IP, the internet access from the private subnet.
- ```alb_dns_name``` : ALB Public DNS Name which used as the A record to the cluster.

### Cleanup
- To destroy **ALL** the AWS resources run ```terraform destroy```
- to destroy specific instance, use ```terraform taint some_aws_resource.resource_name``` and then apply.

# Trouble shooting
**Terraform apply went fine, but cant see website after more then 5 minutes**
- **Verify the healtcheck is fine and traffic routed to pod** : AWS target group health check via AWS UI
- **Verify the pod is running on the cluster** : SSH the cluster via Bastion and verify its running the ngnix pod via ```microk8s kubectl get all```
- **Verify its not the user_data script** : ```cat init.log``` to verify the initial installation and setup of the cluster were successful by the ```user_data``` script

**Got error of credentials when run ```terraform plan/apply```**
- **Verify AWS credentials in place** : Verify youve exported the ```AWS_ACCESS_KEY_ID``` AND ```AWS_SECRET_ACCESS_KEY``` correctly at the Modify section of the Getting Started. if so you should see the output when running ```echo $AWS_ACCESS_KEY_ID``` locally



## Assignment Submission
1. **Application URL**: [https://humanity-project.com](http://humanity-project.com)
2. [GitHub Repository URL](https://github.com/MrAnderson-1999/moveo_nginx)
---

## Sources
ACL's and Security groups levels: https://www.linkedin.com/pulse/connecting-internet-from-ec2-instance-private-subnet-aws-thandra/
