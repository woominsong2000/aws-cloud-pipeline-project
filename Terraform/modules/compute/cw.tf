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
  endpoint  = "woominsong2000@naver.com"
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
}