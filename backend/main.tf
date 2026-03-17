provider "aws" {
  region = "ap-northeast-2"
}

# 1. 상태 파일 보관할 S3
resource "aws_s3_bucket" "terraform_state" {
  bucket = "aws-cloud-pipeline-tfstate-hong"

  lifecycle {
    prevent_destroy = true
  }
}

# S3 버저닝 활성화
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "aws-cloud-pipeline-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}