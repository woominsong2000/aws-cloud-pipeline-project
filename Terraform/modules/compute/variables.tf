# 1. 경락님께 받아올 네트워크 정보
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
  default     = "t3.medium"
}

# 3. Lambda용 ECR (최상위 main에서 넘겨주는 ecr url을 compute 내에서 사용하게끔)
variable "lambda_ecr_url" {
  type        = string
  description = "ECR URL for Lambda"
}

# 4. api용 ECR
variable "api_ecr_url" {
  type        = string
  description = "ECR URL for API Server"
}

variable "source_bucket_id" {
  description = "이미지가 업로드될 실제 S3 버킷 이름"
  type        = string
}

variable "source_bucket_arn" {
  description = "원본 S3 버킷의 ARN"
  type        = string
}

# cloud watch용
variable "sqs_queue_name" {
  description = "감시할 메인 SQS 큐 이름"
  type        = string
}

variable "sqs_dlq_name" {
  description = "감시할 DLQ 이름"
  type        = string
}

variable "lambda_function_name" {
  description = "감시할 Lambda 함수 이름"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL"
  type        = string
  sensitive   = true
}