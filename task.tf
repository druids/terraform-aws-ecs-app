resource "aws_ecs_task_definition" "application" {
  family = local.name

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_execution.arn

  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  container_definitions = var.create_alb_resources ? module.container_definition_alb[0].json_map_encoded : module.container_definition_noalb[0].json_map_encoded

  tags = local.tags
}
