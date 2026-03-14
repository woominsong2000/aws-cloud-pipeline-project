# 1. 프로젝트 이름 (모든 리소스의 이름표가 됩니다)
variable "project_name" {
  description = "리소스 식별을 위한 접두어"
  type        = string
  default = "img-pipe"
}

# 2. 원본 S3 버킷의 ARN (SQS 정책에서 '누가 메시지를 보낼지' 확인하는 용도)
variable "source_bucket_arn" {
  type        = string
  description = "storage 모듈에서 생성된 원본 S3의 ARN"
}