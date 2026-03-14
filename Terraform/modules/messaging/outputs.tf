output "sqs_queue_arn" {
  value       = aws_sqs_queue.main.arn
  description = "람다가 메시지를 읽어갈 주소(ARN) == 트리거" 
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.main.id
  description = "나중에 애플리케이션에서 큐 주소가 필요할 때 사용"
}