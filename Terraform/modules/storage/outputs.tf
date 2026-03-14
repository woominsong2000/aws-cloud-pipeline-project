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