variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "airbyte-enterprise"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "enable_cluster_encryption" {
  description = "Enable envelope encryption for cluster secrets"
  type        = bool
  default     = true
}

variable "node_groups_defaults" {
  description = "Map of default configurations for all node groups"
  type = object({
    disk_size      = number
    instance_types = list(string)
  })
  default = {
    disk_size      = 100
    instance_types = ["t3.xlarge"]
  }
}

variable "db_username" {
  description = "Username for RDS instance"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for RDS instance"
  type        = string
  sensitive   = true
}
