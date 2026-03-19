# 1. 메인 큐: S3가 던진 메시지가 들어오는 곳
resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-queue"
  visibility_timeout_seconds = 360 # 메시지 중복 처리 방지를 위한 은닉 시간

  # [중요] 나중에 아래에서 만들 DLQ와 연결하는 설정
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn # 가독성을 위해 메인큐를 위에 서술, 실제 리소스는 DLQ -> 메인큐 순서로 생성
    maxReceiveCount     = 3
  }) # 3회 읽기 실패시 DLQ로 전송

  tags = {
    Name = "${var.project_name}-queue"
  }
}

# 2. DLQ: 3번 실패한 메시지가 격리되는 곳
resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-dlq"

  tags = {
    Name = "${var.project_name}-dlq"
  }
}

# 3. S3 이벤트 알림: source 버킷에 이미지가 생성되면 SQS에 알림
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.source_bucket_id

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }

  depends_on = [aws_sqs_queue_policy.main_policy]
}

# 4. 정책: S3가 이 큐에 메시지를 던질 수 있게 허락함
resource "aws_sqs_queue_policy" "main_policy" {
  queue_url = aws_sqs_queue.main.id # 큐 주소

  policy = jsonencode({
    Version = "2012-10-17" # 1. 버전
    Statement = [
      {
        Effect    = "Allow" # 2. 허용
        Principal = { Service = "s3.amazonaws.com" } # 3. '누가' : S3
        Action    = "sqs:SendMessage"                # 4. '행동' : 메시지를 보내는 것을
        Resource  = aws_sqs_queue.main.arn          # 5. '어떤 리소스' : 메인 큐
        Condition = {
          ArnLike = {
            "aws:SourceArn" = var.source_bucket_arn # 단, 지정된 S3 버킷만!
          }
        }
      }
    ]
  })
}