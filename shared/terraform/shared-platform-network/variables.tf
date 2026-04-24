variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used in tags."
  type        = string
  default     = "msa"
}

variable "environment" {
  description = "Environment name used in resource names."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Additional tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the shared platform VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs for the gateway ALB and NAT gateway."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs for ECS tasks, Redis, Monitoring, and internal ALBs."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a single NAT gateway for private subnet egress."
  type        = bool
  default     = true
}

variable "private_hosted_zone_name" {
  description = "Route53 private hosted zone name for service-to-service DNS."
  type        = string
  default     = "internal.platform.local"
}
