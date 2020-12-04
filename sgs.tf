resource "aws_security_group" "application" {
  name        = local.name
  vpc_id      = var.vpc_id
  description = "${local.name} security group"

  dynamic "ingress" {
    for_each = var.create_alb_resources ? [1] : []

    content {
      protocol        = "tcp"
      from_port       = 1024
      to_port         = 65535
      security_groups = data.aws_lb.alb.security_groups
    }
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
