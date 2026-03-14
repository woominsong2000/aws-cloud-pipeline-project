variable "aws_region" {
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  type        = string
  default     = "wonwoogotosamsung"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "s3_bucket_name" {
  type        = string
  default     = "s3-image-storage-hong"
}

variable "instance_type" {
  description = "EC2 인스턴스 사양"
  type        = string
  default     = "t3.medium" 
}