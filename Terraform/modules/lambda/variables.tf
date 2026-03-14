variable "project_name" {
  description = "리소스 식별을 위한 접두어"
  type        = string
}

variable "sqs_queue_arn" {
  description = "Lambda 트리거로 사용할 SQS 큐 ARN"
  type        = string
}

variable "source_bucket_id" {
  description = "원본 이미지가 업로드되는 S3 버킷 이름"
  type        = string
}

variable "processed_bucket_id" {
  description = "처리된 이미지가 저장될 S3 버킷 이름"
  type        = string
}

variable "ecr_repository_url" {
  description = "Lambda 컨테이너 이미지 ECR URL"
  type        = string
}
