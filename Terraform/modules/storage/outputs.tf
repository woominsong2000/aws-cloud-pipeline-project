output "source_bucket_arn" {
  value       = aws_s3_bucket.source.arn
  description = "원본 S3 버킷의 Amazon Resource Name (SQS 권한 설정 시 필요)"
}

output "source_bucket_id" {
  value       = aws_s3_bucket.source.id
  description = "원본 S3 버킷의 이름"
}

output "processed_bucket_id" {
  value       = aws_s3_bucket.processed.id
  description = "처리본 S3 버킷의 이름"
}

# 원우님 람다용 ECR 주소 내보내기
output "lambda_ecr_url" {
  description = "The URL of the Lambda ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

# 유나 API 서버용 ECR 주소 내보내기
output "api_ecr_url" {
  description = "The URL of the API ECR repository"
  value       = aws_ecr_repository.api_repo.repository_url
}