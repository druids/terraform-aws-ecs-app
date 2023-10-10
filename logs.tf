resource "aws_cloudwatch_log_group" "application_logs" {
  name              = local.name
  retention_in_days = var.log_retention
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "nginx_logs" {
  count = var.create_alb_resources && var.create_nginx ? 1 : 0

  name              = "${local.name}-nginx"
  retention_in_days = var.log_retention
  tags              = var.tags
}

output "cloudwatch_log_group_arn" {
  value = aws_cloudwatch_log_group.application_logs.arn
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.application_logs.name
}
