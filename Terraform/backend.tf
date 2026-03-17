terraform {
  backend "s3" {
    bucket         = "aws-cloud-pipeline-tfstate-hong"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "aws-cloud-pipeline-locks"
    encrypt        = true
  }
}