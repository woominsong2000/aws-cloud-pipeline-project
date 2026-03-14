# 1. 경락님께 받아서 적을 네트워크 정보
variable "vpc_id" {
  description = "VPC ID from network module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public Subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs for EC2 ASG"
  type        = list(string)
}

# 2. 공통 설정
variable "project_name" {
  description = "리소스 식별을 위한 접두어"
  type        = string
  default = "img-pipe"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ecr_repository_url" {
  description = "ECR repository URL for EC2 to pull images"
  type        = string
}