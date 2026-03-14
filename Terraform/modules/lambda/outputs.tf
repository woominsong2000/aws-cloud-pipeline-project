output "lambda_function_arn" {
  value       = aws_lambda_function.image_processor.arn
  description = "Lambda 함수 ARN"
}

output "lambda_function_name" {
  value       = aws_lambda_function.image_processor.function_name
  description = "Lambda 함수 이름"
}
