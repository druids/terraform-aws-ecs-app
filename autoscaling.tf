resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.scheduling_strategy == "REPLICA" ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on         = [aws_ecs_service.application]
}

// metric used for auto scale
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  count               = var.scheduling_strategy == "REPLICA" ? 1 : 0
  alarm_name          = "${local.name_underscore}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.scale_up

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.name
  }

  alarm_actions = [aws_appautoscaling_policy.up[0].arn]
  depends_on    = [aws_appautoscaling_policy.up[0]]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  count               = var.scheduling_strategy == "REPLICA" ? 1 : 0
  alarm_name          = "${local.name_underscore}_cpu_utilization_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.scale_down

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.name
  }

  alarm_actions = [aws_appautoscaling_policy.down[0].arn]
  depends_on    = [aws_appautoscaling_policy.down[0]]
}

resource "aws_appautoscaling_policy" "up" {
  count              = var.scheduling_strategy == "REPLICA" ? 1 : 0
  name               = "${local.name_underscore}_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_appautoscaling_policy" "down" {
  count              = var.scheduling_strategy == "REPLICA" ? 1 : 0
  name               = "${local.name_underscore}_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}
