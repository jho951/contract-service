output "vpc_id" {
  description = "Shared VPC ID."
  value       = aws_vpc.shared.id
}

output "vpc_cidr" {
  description = "Shared VPC CIDR block."
  value       = aws_vpc.shared.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs for gateway ALB and NAT."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for ECS services, Redis, Monitoring, and internal ALBs."
  value       = aws_subnet.private[*].id
}

output "private_hosted_zone_id" {
  description = "Route53 private hosted zone ID."
  value       = aws_route53_zone.private.zone_id
}

output "private_hosted_zone_name" {
  description = "Route53 private hosted zone name."
  value       = aws_route53_zone.private.name
}
