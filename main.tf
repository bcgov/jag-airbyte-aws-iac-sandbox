# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.30.3"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    general = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t3.xlarge"]
      capacity_type  = "ON_DEMAND"

      # Add recommended labels for Airbyte workloads
      labels = {
        Environment = var.environment
        "airbyte.io/workload-type" = "general"
      }

      # Add taints to ensure Airbyte pods land on correct nodes
      taints = []

      # Add additional security groups if needed
      additional_security_group_ids = []
    }
    
    # Add dedicated node group for Airbyte workers
    workers = {
      desired_size = 2
      min_size     = 1
      max_size     = 5

      instance_types = ["t3.2xlarge"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = var.environment
        "airbyte.io/workload-type" = "worker"
      }
    }
  }

  # Enable OIDC provider for service account integration
  enable_irsa = true

  # Add cluster encryption
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  # Update EKS module configuration to enable logging
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

# Add KMS key for cluster encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Add RDS subnet group
resource "aws_db_subnet_group" "airbyte" {
  name       = "${var.cluster_name}-rds"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Add RDS security group
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds"
  description = "Security group for Airbyte RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Add RDS instance
resource "aws_db_instance" "airbyte" {
  identifier        = "${var.cluster_name}-db"
  engine            = "postgres"
  engine_version    = "13.7"
  instance_class    = "db.t3.medium"
  allocated_storage = 20

  db_name  = "airbyte"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.airbyte.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  skip_final_snapshot    = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# S3 bucket for state storage
resource "aws_s3_bucket" "state" {
  bucket = "${var.cluster_name}-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Get list of availability zones
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
