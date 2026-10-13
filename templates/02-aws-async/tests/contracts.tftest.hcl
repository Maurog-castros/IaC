mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = { arn = "arn:aws:sqs:us-east-1:123456789012:demo" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/demo" }
  }
  mock_resource "aws_lambda_function" {
    defaults = { arn = "arn:aws:lambda:us-east-1:123456789012:function:demo" }
  }
}
mock_provider "archive" {}
run "retry_contract" {
  command = plan
  assert {
    condition     = aws_sqs_queue.jobs.visibility_timeout_seconds >= aws_lambda_function.worker.timeout * 6
    error_message = "Visibility debe cubrir seis veces el timeout del worker."
  }
  assert {
    condition     = contains(aws_lambda_event_source_mapping.jobs.function_response_types, "ReportBatchItemFailures") && aws_sqs_queue.dlq.message_retention_seconds > aws_sqs_queue.jobs.message_retention_seconds
    error_message = "Se requieren fallos parciales y mayor retención en DLQ."
  }
}
