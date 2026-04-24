terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  resource_prefix = "${var.environment}-${var.project_name}-shared-network"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "shared-platform-network"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "shared" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "shared" {
  vpc_id = aws_vpc.shared.id

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.shared.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.shared.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.shared.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shared.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "shared" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.shared]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.shared.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.shared[0].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route53_zone" "private" {
  name = var.private_hosted_zone_name

  vpc {
    vpc_id = aws_vpc.shared.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-private-zone"
  })
}
