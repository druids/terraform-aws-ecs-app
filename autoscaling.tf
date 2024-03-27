resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.scheduling_strategy == "REPLICA" ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    replace_triggered_by = [
      # Replace `aws_appautoscaling_target` each time this instance of
      # the `aws_ecs_service` is replaced.
      aws_ecs_service.application.id
    ]
  }

  depends_on = [aws_ecs_service.application]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  count               = var.scheduling_strategy == "REPLICA" ? 1 : 0
  alarm_name          = "${local.name_underscore}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_up

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.name
  }

  alarm_actions = [aws_appautoscaling_policy.up[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  count               = var.scheduling_strategy == "REPLICA" ? 1 : 0
  alarm_name          = "${local.name_underscore}_cpu_utilization_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_down

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.name
  }

  alarm_actions = [aws_appautoscaling_policy.down[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "sqs_up" {
  count = var.scheduling_strategy == "REPLICA" && var.sqs_scaling_enabled ? 1 : 0

  alarm_name          = "${local.name}-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.sqs_scaling_evaluation_periods
  metric_name         = var.sqs_scaling_metric_name
  namespace           = "AWS/SQS"
  period              = var.sqs_scaling_period
  statistic           = "Maximum"
  threshold           = var.sqs_scaling_threshold

  dimensions = {
    QueueName = var.sqs_scaling_queue_name
  }

  alarm_actions     = [aws_appautoscaling_policy.sqs_up[0].arn]
  alarm_description = "Monitors ApproximateAgeOfOldestMessage in SQS queue"
}

resource "aws_cloudwatch_metric_alarm" "sqs_down" {
  count = var.scheduling_strategy == "REPLICA" && var.sqs_scaling_enabled ? 1 : 0

  alarm_name          = "${local.name}-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.sqs_scaling_evaluation_periods
  metric_name         = var.sqs_scaling_metric_name
  namespace           = "AWS/SQS"
  period              = var.sqs_scaling_period
  statistic           = "Maximum"
  threshold           = var.sqs_scaling_threshold

  dimensions = {
    QueueName = var.sqs_scaling_queue_name
  }

  alarm_actions     = [aws_appautoscaling_policy.sqs_down[0].arn]
  alarm_description = "Monitors ApproximateAgeOfOldestMessage in SQS queue"
}

resource "aws_appautoscaling_policy" "up" {
  count              = var.scheduling_strategy == "REPLICA" ? 1 : 0
  name               = "${local.name_underscore}_scale_up"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "down" {
  count              = var.scheduling_strategy == "REPLICA" ? 1 : 0
  name               = "${local.name_underscore}_scale_down"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_policy" "sqs_up" {
  count = var.scheduling_strategy == "REPLICA" && var.sqs_scaling_enabled ? 1 : 0

  name               = "${local.name_underscore}_sqs_up"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "sqs_down" {
  count = var.scheduling_strategy == "REPLICA" && var.sqs_scaling_enabled ? 1 : 0

  name               = "${local.name_underscore}_sqs_down"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }
}
