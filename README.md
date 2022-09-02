# rke2-automation

#### Description
1. This repo will automate the provisioning of ec2 instances for RKE2 cluster in AWS
2. infra = 1 bastion host and 1 master node and 3 worker nodes (5 host total)
3. After servers are ready, ansible is used to automate setting up RKE2 on all nodes
4. Once script is completed, kubectl can be run from bastion

#### Requirements
1. AWS Account with correct user permissions and access keys
2. AWS VPC with Subnet and SG configured
3. IAM role for bastion EC2 isntance
4. 2 ssh key pairs
