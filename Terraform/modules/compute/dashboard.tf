resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "${var.project_name}-monitoring-center"

  dashboard_body = jsonencode({
    widgets = [
      # --- ROW 1: ALB & ASG (경락 담당) ---
      {
        type   = "metric", x = 0, y = 0, width = 6, height = 6,
        properties = {
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.this.arn_suffix]],
          view    = "timeSeries", stacked = false, region = "ap-northeast-2", title = "ALB 초당 요청 수",
          period  = 10, stat = "Sum"
        }
      },
      {
        type   = "metric", x = 6, y = 0, width = 6, height = 6,
        properties = {
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.this.name]],
          view    = "timeSeries", stacked = false, region = "ap-northeast-2", title = "EC2 CPU 사용률",
          period  = 10, stat = "Average",
          annotations = { horizontal = [{ label = "ASG 트리거 임계치", value = 70, color = "#d62728" }] }
        }
      },
      {
        type   = "metric", x = 12, y = 0, width = 6, height = 6,
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.this.name, { label = "Desired (실선)" }],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.this.name, { label = "InService (점선)" }]
          ],
          view    = "timeSeries", stacked = false, region = "ap-northeast-2", title = "ASG 인스턴스 수 변화",
          period  = 10, stat = "Average"
        }
      },
      {
        type   = "metric", x = 18, y = 0, width = 6, height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.this.arn_suffix, "TargetGroup", aws_lb_target_group.this.arn_suffix, { stat = "p95", label = "p95 (실선)" }],
            ["...", { stat = "p99", label = "p99 (점선)" }]
          ],
          view    = "timeSeries", stacked = false, region = "ap-northeast-2", title = "ALB 응답 시간 (p95/p99)",
          period  = 10
        }
      },

      # --- ROW 2: SQS & LAMBDA (원우 담당) ---
      {
        type   = "metric", x = 0, y = 6, width = 6, height = 6,
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name, { label = "Main Queue" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_dlq_name, { color = "#d62728", label = "DLQ" }]
          ],
          view    = "timeSeries", region = "ap-northeast-2", title = "SQS 큐 깊이",
          period  = 10, stat = "Maximum"
        }
      },
      {
        type   = "metric", x = 6, y = 6, width = 6, height = 6,
        properties = {
          metrics = [["AWS/Lambda", "ConcurrentExecutions", "FunctionName", var.lambda_function_name]],
          view    = "timeSeries", region = "ap-northeast-2", title = "Lambda 동시 실행 수",
          period  = 10, stat = "Maximum"
        }
      },
      {
        type   = "metric", x = 12, y = 6, width = 6, height = 6,
        properties = {
          metrics = [["AWS/Lambda", "Errors", "FunctionName", var.lambda_function_name]],
          view    = "bar", region = "ap-northeast-2", title = "Lambda 에러 수 (Ground Truth 대조용)",
          period  = 60, stat = "Sum"
        }
      },
      {
        type   = "metric", x = 18, y = 6, width = 6, height = 6,
        properties = {
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", var.sqs_queue_name, { label = "Sent (수신량, 실선)" }],
            ["AWS/SQS", "NumberOfMessagesDeleted", "QueueName", var.sqs_queue_name, { label = "Deleted (처리량, 점선)" }]
          ],
          view    = "timeSeries", region = "ap-northeast-2", title = "SQS 처리량 vs 수신량",
          period  = 10, stat = "Sum"
        }
      },

      # --- ROW 3: 공동 알람 현황판 (우민 OR 전체) ---
      {
        type   = "alarm", x = 0, y = 12, width = 24, height = 6,
        properties = {
          title  = "CloudWatch Alarms 현황",
          alarms = [
            aws_cloudwatch_metric_alarm.high_cpu.arn,
            aws_cloudwatch_metric_alarm.high_requests.arn,
            aws_cloudwatch_metric_alarm.sqs_backlog.arn,
            aws_cloudwatch_metric_alarm.dlq_not_empty.arn,
            aws_cloudwatch_metric_alarm.lambda_error.arn
          ]
        }
      }
    ]
  })
}