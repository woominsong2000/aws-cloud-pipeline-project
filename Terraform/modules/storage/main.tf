# 보안 설정: 버킷을 외부에서 함부로 못 보게 막음
resource "aws_s3_bucket_public_access_block" "source_pab" {
  bucket = aws_s3_bucket.source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "processed_pab" {
  bucket = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 1. 원본 버킷: EC2가 이미지를 업로드하는 곳
resource "aws_s3_bucket" "source" {
  bucket = "${var.project_name}-source-${var.aws_account_id}"

  tags = {
    Name = "${var.project_name}-source"
  }
}

# 2. 처리본 버킷: Lambda가 리사이즈해서 저장하는 곳
resource "aws_s3_bucket" "processed" {
  bucket = "${var.project_name}-processed-${var.aws_account_id}"

  tags = {
    Name = "${var.project_name}-processed"
  }
}
