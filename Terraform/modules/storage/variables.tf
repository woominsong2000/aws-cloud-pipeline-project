variable "project_name" {
  type        = string
  description = "전체 프로젝트 이름 (compute와 동일하게 유지)"
}

variable "aws_account_id" {
  type        = string
  description = "계정 ID"
}

variable "environment" {
  type        = string
  default     = "dev"
}