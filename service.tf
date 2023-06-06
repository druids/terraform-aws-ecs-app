data "aws_ecs_task_definition" "application" {
  task_definition = aws_ecs_task_definition.application.family
  depends_on      = [aws_ecs_task_definition.application]
}

resource "aws_ecs_service" "application" {
  name    = var.name
  cluster = data.aws_ecs_cluster.ecs.arn

  task_definition                    = "${aws_ecs_task_definition.application.family}:${max(aws_ecs_task_definition.application.revision, data.aws_ecs_task_definition.application.revision)}"
  launch_type                        = var.requires_compatibilities[0]
  desired_count                      = var.min_capacity
  deployment_maximum_percent         = var.max_healthy
  deployment_minimum_healthy_percent = var.min_healthy
  health_check_grace_period_seconds  = var.healthcheck_grace
  scheduling_strategy                = var.scheduling_strategy

  propagate_tags = "SERVICE"

  dynamic "load_balancer" {
    for_each = var.create_alb_resources ? [1] : []

    content {
      container_name   = var.create_nginx ? var.nginx_container_name : var.name
      container_port   = var.port
      target_group_arn = aws_lb_target_group.application[0].arn
    }
  }

  dynamic "network_configuration" {
    for_each = contains(var.requires_compatibilities, "FARGATE") ? [1] : []

    content {
      subnets          = var.private_subnet_ids
      security_groups  = [aws_security_group.application.id]
      assign_public_ip = var.assign_public_ip
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_iam_role.ecs_task_execution]

  tags = var.tags
}
