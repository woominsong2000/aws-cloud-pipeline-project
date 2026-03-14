variable "project_name" {
  description = "리소스 식별을 위한 접두어"
  type        = string
  default = "img-pipe"
}

variable "aws_account_id" {
  type        = string
  description = "계정 ID"
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "sqs_queue_arn" {
  type        = string
  description = "이벤트를 보낼 SQS 큐의 ARN"
}