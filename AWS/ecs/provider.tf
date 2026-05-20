terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Override bucket/key/table via backend.hcl at init (see README):
  #   terraform init -reconfigure -backend-config=../../backend.hcl
  backend "s3" {
    profile        = "terraform-infra"
    bucket         = "YOUR_STATE_BUCKET"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "YOUR_LOCK_TABLE"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
