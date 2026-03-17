# 1. EC2가 사용할 역할(Role) 만들기
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
    ]
  })
}

# 2. ECR에서 이미지를 가져올 수 있는 권한(Policy) 붙여주기
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. EC2에 이 역할을 입혀줄 '인스턴스 프로파일' 만들기
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# 4. EC2가 Session Manager(SSM)에 접속
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 6. EC2가 S3에 사진을 올릴 수 있게 허용하는 정책
resource "aws_iam_role_policy" "ec2_s3_upload" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        # 지정된 바구니 안의 모든 파일(/*)에 대해 업로드 허용
        Resource = "${var.source_bucket_arn}/*"
      }
    ]
  })
}


resource "aws_iam_role" "slack_lambda_role" {
  name = "${var.project_name}-slack-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 기본 실행 권한(로그 기록 등) 붙여주기
resource "aws_iam_role_policy_attachment" "slack_lambda_basic" {
  role       = aws_iam_role.slack_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}