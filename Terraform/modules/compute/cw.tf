# 1. SNS 이메일 알림 통로
resource "aws_sns_topic" "admin_alert" {
  name = "${var.project_name}-admin-alert"
}

# 1-1. 설계자 구독(유나)
resource "aws_sns_topic_subscription" "email_yuna" {
  topic_arn = aws_sns_topic.admin_alert.arn
  protocol  = "email"
  endpoint  = "h.hatmanity@gmail.com"
}

# 1-2. 대시보드 담당자 구독(우민)
resource "aws_sns_topic_subscription" "email_woomin" {
  topic_arn = aws_sns_topic.admin_alert.arn
  protocol  = "email"
  endpoint  = "woominsong2000@gmail.com"
}

# 2. SNS 연결 : ALB 요청 수
resource "aws_cloudwatch_metric_alarm" "high_requests" {
  alarm_name          = "${var.project_name}-high-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "50"

  dimensions = {
    TargetGroup  = aws_lb_target_group.this.arn_suffix
    LoadBalancer = aws_lb.this.arn_suffix
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_out_by_request.arn,
    aws_sns_topic.admin_alert.arn
  ]
  ok_actions = [aws_autoscaling_policy.scale_in_by_request.arn]
}

# 3. SNS 연결 : CPU 사용량
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_out_by_cpu.arn,
    aws_sns_topic.admin_alert.arn
  ]
  ok_actions = [aws_autoscaling_policy.scale_in_by_cpu.arn]
}

# 4. SQS 지연 알람: 처리되지 않은 이미지가 10개 이상 쌓였을 때
resource "aws_cloudwatch_metric_alarm" "sqs_backlog" {
  alarm_name          = "${var.project_name}-sqs-backlog"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10" # 10개 이상 쌓이면 경고

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  alarm_actions = [aws_sns_topic.admin_alert.arn]
}

# 5. DLQ 알람: 큐에 실패한 메시지가 존재할 때 (수정 버전)
resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "${var.project_name}-dlq-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"

  # 지표 이름을 변경합니다!
  metric_name         = "ApproximateNumberOfMessagesVisible"

  namespace           = "AWS/SQS"
  period              = "60"

  # 합계(Sum) 보다는 최대치(Maximum) 또는 평균(Average)으로
  # 현재 쌓여있는 '양'을 체크하는 것이 좋습니다.
  statistic           = "Maximum"

  threshold           = "0" # 0보다 크면(즉, 1개라도 쌓이면) 알람

  dimensions = {
    QueueName = var.sqs_dlq_name
  }

  alarm_actions = [aws_sns_topic.admin_alert.arn]
}


# 6. Lambda 에러 알람: 이미지 리사이징 중 코드가 터졌을 때
resource "aws_cloudwatch_metric_alarm" "lambda_error" {
  alarm_name          = "${var.project_name}-lambda-error"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.admin_alert.arn]
}


# 1. 압축 데이터 (이건 하나만 있어야 함)
data "archive_file" "slack_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../app/slack-notifier/handler.py"
  output_path = "${path.module}/slack_lambda.zip"
}

# 2. 람다 함수 정의 (이것도 딱 하나만!)
resource "aws_lambda_function" "slack_notifier" {
  function_name = "${var.project_name}-slack-notifier"
  role          = aws_iam_role.slack_lambda_role.arn
  handler       = "handler.handler"
  runtime       = "python3.11"

  # 재료 정보가 포함된 이 버전으로 남겨두세요
  filename         = data.archive_file.slack_lambda_zip.output_path
  source_code_hash = data.archive_file.slack_lambda_zip.output_base64sha256
  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}

# 2. SNS가 이 람다를 깨울 수 있게 허용
resource "aws_lambda_permission" "sns_call_slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.admin_alert.arn
}

# 3. SNS 구독 추가 (Email 대신/함께 Lambda로 발송)
resource "aws_sns_topic_subscription" "slack_subscription" {
  topic_arn = aws_sns_topic.admin_alert.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}