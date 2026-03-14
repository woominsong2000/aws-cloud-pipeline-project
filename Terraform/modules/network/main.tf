# VPC
resource "aws_vpc" "project_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

# igw
resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_vpc.id
  tags   = { Name = "${var.project_name}-igw" }
}

# public sub
resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = { Name = "${var.project_name}-public-subnet-${count.index + 1}" }
}

# private sub
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = { Name = "${var.project_name}-private-subnet-${count.index + 1}" }
}

# public_rt
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# private_rt
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.project_vpc.id
  tags   = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# s3gw
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.project_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids   = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]
  tags = { Name = "${var.project_name}-s3-gw-ep" }
}

# s3
resource "aws_s3_bucket" "storage" {
  bucket = var.s3_bucket_name
  tags   = { Name = var.s3_bucket_name }
}

resource "aws_s3_bucket_public_access_block" "storage_block" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_region" "current" {}