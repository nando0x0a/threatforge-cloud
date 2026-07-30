terraform {
  required_version = ">= 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Local state for now — single operator, single machine (aiserver). Revisit
  # a remote S3 backend only if a second person or machine needs to run
  # `terraform apply` against this state.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "ThreatForge"
      ManagedBy = "Terraform"
      Repo      = "nando0x0a/threatforge-cloud"
    }
  }
}
