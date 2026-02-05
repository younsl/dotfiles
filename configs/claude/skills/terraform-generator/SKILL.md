# Terraform Configuration Generator

Generate production-ready Terraform configurations following best practices.

## When to Use
- Creating new infrastructure resources
- Setting up new Terraform modules
- Converting infrastructure requirements to IaC

## Core Rules

### 1. Use S3 Native State Locking

Set `use_lockfile = true` in S3 backend. No DynamoDB needed.

### 2. Pin Provider Versions

Always specify version constraints (e.g., `version = "~> 5.0"`).

### 3. Enable Encryption by Default

Enable encryption at rest for S3, EBS, RDS resources.

### 4. Use Variables with Validation

Add `validation` blocks for input variables.

### 5. Never Hardcode Secrets

Use SSM Parameter Store or Secrets Manager for credentials.

## Project Structure

### Standard Layout
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── stg/
│   └── prd/
├── modules/
│   └── <module-name>/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── README.md
```

## Configuration Templates

### Provider Configuration
```hcl
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }

  # S3 Native State Locking (Terraform 1.10+, Recommended)
  backend "s3" {
    bucket       = "terraform-state-bucket"
    key          = "env/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true  # S3 native locking
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  }
}
```

### Variables
```hcl
# variables.tf

variable "environment" {
  description = "Environment name (dev, stg, prd)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be dev, stg, or prd."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
```

### Outputs
```hcl
# outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = false
}

output "database_password" {
  description = "Database password"
  value       = random_password.db.result
  sensitive   = true
}
```

## Module Templates

### Module Structure
```hcl
# modules/vpc/main.tf

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${var.azs[count.index]}"
    Type = "private"
  })
}
```

### Module Variables
```hcl
# modules/vpc/variables.tf

variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

## AWS Resource Patterns

### EKS Cluster
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    system = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["m6i.large"]

      labels = {
        role = "system"
      }

      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  tags = var.tags
}
```

### S3 Bucket
```hcl
resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.environment}-${var.bucket_name}"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## Best Practices

### Naming Convention
- Use consistent naming: `${project}-${environment}-${resource}`
- Use lowercase and hyphens
- Include environment in resource names

### Security
- Never hardcode secrets (use SSM Parameter Store, Secrets Manager)
- Enable encryption by default
- Use least-privilege IAM policies
- Enable logging for auditable resources

### State Management
- Use remote state with S3 backend
- Use S3 native locking (`use_lockfile = true`) - Terraform 1.10+
- Enable state encryption
- Separate state per environment

```hcl
backend "s3" {
  bucket       = "terraform-state-bucket"
  key          = "env/terraform.tfstate"
  region       = "ap-northeast-2"
  encrypt      = true
  use_lockfile = true  # S3 native locking
}
```

### Code Quality
- Use `terraform fmt` for formatting
- Use `terraform validate` before apply
- Run `tflint` for linting
- Use `checkov` for security scanning

## Validation
```bash
# Format
terraform fmt -recursive

# Validate
terraform validate

# Lint
tflint --recursive

# Security scan
checkov -d .

# Plan
terraform plan -out=tfplan
```
