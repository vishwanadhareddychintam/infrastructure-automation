variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name (must match backend profile in provider.tf or backend.hcl)"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Two public subnet CIDRs (one per AZ)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Two private subnet CIDRs (one per AZ)"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "name_prefix" {
  type        = string
  description = "Base prefix for resource Name tags (environment is appended)"
}

variable "environment" {
  type        = string
  description = "Environment name appended as YourApplicationName-<environment> on resources"
}
