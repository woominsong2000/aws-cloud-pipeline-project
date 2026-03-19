# 1. IAM Role: Lambda가 AWS 서비스에 접근할 수 있는 권한
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 2. IAM Policy: Lambda가 실제로 사용할 권한 목록
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3 source 버킷에서 이미지 읽기
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.source_bucket_id}/*"
      },
      {
        # S3 processed 버킷에 결과 저장
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.processed_bucket_id}/*"
      },
      {
        # SQS에서 메시지 읽고 삭제
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        # CloudWatch Logs 기록
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 3. Lambda 함수: ECR 컨테이너 이미지 기반
resource "aws_lambda_function" "image_processor" {
  function_name = "${var.project_name}-image-processor"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${var.lambda_ecr_url}:latest"

  timeout     = 60  # 이미지 처리 시간 고려
  memory_size = 512

  environment {
    variables = {
      PROCESSED_BUCKET = var.processed_bucket_id
    }
  }

  tags = {
    Name = "${var.project_name}-image-processor"
  }
  # Lambda의 성능 모니터링과 디버깅을 위해 활성화된 트레이싱 설정
  tracing_config { 
    mode = "Active"
  }
}

# 4. IAM 권한 추가 (X-Ray 트레이싱을 위한 권한)
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policies/AWSXRayDaemonWriteAccess"
}

# 5. SQS → Lambda 트리거 연결
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.image_processor.arn
  batch_size       = 1  # 이미지 1장씩 처리
}
