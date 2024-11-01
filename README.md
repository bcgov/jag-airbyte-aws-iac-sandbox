# Airbyte Enterprise AWS Infrastructure

This repository contains Terraform configurations to deploy Airbyte Enterprise on AWS using EKS (Elastic Kubernetes Service). The infrastructure is designed following AWS and Terraform best practices for production-grade deployments.

## Architecture Overview

The infrastructure consists of:
- EKS cluster running in private subnets with t3.xlarge nodes([1](https://docs.airbyte.com/enterprise-setup/implementation-guide))
- RDS PostgreSQL database for Airbyte metadata
- S3 bucket for state storage
- Application Load Balancer (ALB) for ingress
- CloudWatch logging enabled

## Prerequisites

- AWS CLI installed and configured
- Terraform >= 1.3
- kubectl installed
- A valid Airbyte Enterprise license key([1](https://docs.airbyte.com/enterprise-setup/implementation-guide))
- Helm installed

## Infrastructure Components

### EKS Cluster
- Version 1.30
- t3.xlarge instance types
- Auto-scaling configuration (1-3 nodes)

### RDS Database
- PostgreSQL 13.7
- db.t3.large instance class
- 100GB storage
- Single-AZ deployment (can be upgraded to multi-AZ)

### S3 Storage
- Single bucket for logs, state, and workload output
- Versioning enabled
- Used by Airbyte for state management and logs

### Load Balancer
- Application Load Balancer (ALB)
- HTTP listener on port 80
- IP target type for EKS integration

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

3. Create a terraform.tfvars file with required variables:
```hcl
aws_region = "us-west-2"
environment = "production"
cluster_name = "airbyte-enterprise"
db_username = "airbyte"
db_password = "your-secure-password"
```

4. Deploy the infrastructure:
```bash
terraform plan
terraform apply
```

5. Configure kubectl:
```bash
aws eks update-kubeconfig --region <aws_region> --name <cluster_name>
```

6. Install Airbyte Enterprise:
```bash
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

## Configuration Files

- **terraform.tf**: Provider configurations and version constraints
- **variables.tf**: Input variable definitions
- **outputs.tf**: Output value definitions
- **values.yaml**: Airbyte Helm chart configuration
- **.terraform.lock.hcl**: Terraform dependency lock file

## Important Notes
1. This configuration uses instance profile authentication for S3 access
2. Authentication is currently disabled - enable as needed
3. The RDS instance is deployed in single-AZ mode for cost savings - upgrade to multi-AZ for production
4. HTTP only is configured - add TLS for production use

For production deployments, consider:
1. Enabling TLS for the load balancer
2. Implementing authentication
3. Enabling multi-AZ for RDS
4. Adding additional security groups
5. Implementing network policies
