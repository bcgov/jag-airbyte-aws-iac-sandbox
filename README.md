# jag-airbyte-aws-iac-sandbox
For deploying AirByte Enterprise software using infrastructure-as-code within the BC Public Cloud (AWS).

# Airbyte Enterprise AWS Infrastructure

This repository contains Terraform configurations to deploy Airbyte Enterprise on AWS using EKS (Elastic Kubernetes Service). The infrastructure is designed following AWS and Terraform best practices for production-grade deployments.

## Architecture Overview

The infrastructure consists of:

- VPC with public and private subnets across multiple availability zones
- EKS cluster running in private subnets with t3.xlarge nodes([3](https://docs.airbyte.com/enterprise-setup/implementation-guide))
- NAT Gateway for private subnet connectivity
- Auto-scaling node groups (1-3 nodes)
- Appropriate IAM roles and security groups

## Prerequisites

- AWS CLI installed and configured
- Terraform >= 1.3
- kubectl installed
- A valid Airbyte Enterprise license key([3](https://docs.airbyte.com/enterprise-setup/implementation-guide))
- Helm installed

## Infrastructure Components

### VPC Configuration
The VPC is configured with:
- 3 private subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
- 3 public subnets (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24)
- NAT Gateway for private subnet connectivity
- DNS hostname support enabled

### EKS Cluster
The EKS cluster is configured with:
- Version 1.30
- Managed node groups using t3.xlarge instances
- Auto-scaling configuration (1-3 nodes)
- Private subnet deployment
- Kubernetes control plane logging enabled

## Deployment Instructions

1. Clone the repository:
```bash
git clone https://github.com/bcgov/jag-airbyte-aws-iac-sandbox
cd jag-airbyte-aws-iac-sandbox
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review and update variables in `terraform.tfvars` if needed:
```hcl
aws_region = "us-west-2"
environment = "production"
cluster_name = "airbyte-enterprise"
```

4. Deploy the AWS infrastructure:
```bash
terraform plan
terraform apply
```

5. Configure kubectl to interact with your cluster:
```bash
aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}
```

6. Install Airbyte Enterprise([3](https://docs.airbyte.com/enterprise-setup/implementation-guide)):
```bash
# Add Airbyte helm repository
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace airbyte

# Deploy Airbyte Enterprise
helm install \
  --namespace airbyte \
  --values ./values.yaml \
  airbyte-enterprise \
  airbyte/airbyte
```

## Post-Deployment Configuration

### Scaling([2](https://docs.airbyte.com/enterprise-setup/scaling-airbyte))
- Monitor CPU and Memory usage of connector pods
- Adjust concurrent sync limits as needed
- Configure multiple node groups for better workload isolation
- Enable high availability by running multiple replicas of critical services

### API Access([1](https://docs.airbyte.com/enterprise-setup/api-access-config))
1. Create an application in the Airbyte UI to get client credentials
2. Obtain access tokens for API authentication
3. Use the tokens to interact with Airbyte's API endpoints

## Security Considerations

- EKS cluster deployed in private subnets
- Node groups use AWS-managed node groups for better security
- All necessary security groups automatically configured
- Kubernetes RBAC enabled by default
- Support for AWS Secrets Manager integration

## Monitoring and Logging

The infrastructure comes with:
- CloudWatch logging enabled for EKS control plane
- Container Insights ready to be enabled
- Node groups integrated with CloudWatch
