resource "aws_lb_target_group" "application" {
  count = var.create_alb_resources ? 1 : 0

  name                          = replace(local.name, "/(.{0,31})(.*)/", "$1")
  port                          = var.port
  protocol                      = "HTTP"
  target_type                   = "instance"
  vpc_id                        = var.vpc_id
  deregistration_delay          = var.deregistration_delay
  load_balancing_algorithm_type = var.load_balancing_algorithm_type

  health_check {
    interval            = var.healthcheck_interval
    timeout             = var.healthcheck_timeout
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
    path                = var.healthcheck_path
    matcher             = var.healthcheck_matcher
  }

  tags = local.tags
}

data "aws_lb_listener" "selected443" {
  count = var.create_alb_resources ? 1 : 0

  load_balancer_arn = var.create_alb_resources ? var.alb_arn : null
  port              = var.create_alb_resources ? 443 : null
}

resource "aws_lb_listener_rule" "application" {
  count = var.create_alb_resources ? 1 : 0

  listener_arn = data.aws_lb_listener.selected443[0].arn
  priority     = var.create_alb_resources ? var.alb_priority : null

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application[0].arn
  }

  condition {
    host_header {
      values = var.create_alb_resources ? [var.alb_url] : null
    }
  }

  depends_on = [aws_lb_target_group.application]
}
