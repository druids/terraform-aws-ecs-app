module "container_definition_noalb" { // Without ALB
  count = var.create_alb_resources ? 0 : 1

  source  = "cloudposse/ecs-container-definition/aws"
  version = "v0.57.0"

  container_name  = var.name
  container_image = var.image == "" ? aws_ecr_repository.application[0].repository_url : var.image

  container_cpu                = var.cpu
  container_memory_reservation = var.memory
  container_memory             = var.memory_limit

  port_mappings = var.port != null ? [
    {
      containerPort = var.port
      hostPort      = contains(var.requires_compatibilities, "FARGATE") ? var.port : 0
      protocol      = "tcp"
    },
  ] : []

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.application_logs.name
      awslogs-stream-prefix = "ecs"
    }
  }


  healthcheck = {
    command     = var.container_healthcheck_command
    interval    = var.container_healthcheck_interval
    retries     = var.container_healthcheck_retries
    startPeriod = var.container_healthcheck_start_period
    timeout     = var.container_healthcheck_timeout
  }

  environment = var.environment
  secrets     = var.secrets
}

module "container_definition_alb" { // With ALB
  count = var.create_alb_resources ? 1 : 0

  source  = "cloudposse/ecs-container-definition/aws"
  version = "v0.57.0"

  container_name  = var.name
  container_image = var.image == "" ? aws_ecr_repository.application[0].repository_url : var.image

  container_cpu                = var.cpu
  container_memory_reservation = var.memory
  container_memory             = var.memory_limit

  port_mappings = var.create_nginx || var.port == null ? [] : [
    {
      containerPort = var.port
      hostPort      = contains(var.requires_compatibilities, "FARGATE") ? var.port : 0
      protocol      = "tcp"
    },
  ]

  mount_points = var.create_nginx ? [
    {
      containerPath = "/etc/nginx/conf.d/"
      sourceVolume  = "nginx_config"
      readOnly      = true
    },
  ] : []

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.application_logs.name
      awslogs-stream-prefix = "ecs"
    }
  }

  environment = var.environment
  secrets     = var.secrets
}

module "container_definition_nginx" { // Nginx task
  count = var.create_alb_resources && var.create_nginx ? 1 : 0

  source  = "cloudposse/ecs-container-definition/aws"
  version = "v0.57.0"

  container_name  = var.nginx_container_name
  container_image = var.nginx_container_image

  container_cpu                = var.nginx_container_cpu
  container_memory_reservation = var.nginx_container_memory_reservation
  container_memory             = var.nginx_container_memory

  port_mappings = var.port != null ? [
    {
      containerPort = var.port
      hostPort      = contains(var.requires_compatibilities, "FARGATE") ? var.port : 0
      protocol      = "tcp"
    },
  ] : []

  volumes_from = [
    {
      "sourceContainer" = var.name
      "readOnly"        = true
    },
  ]

  links = var.nginx_links

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.nginx_logs[0].name
      awslogs-stream-prefix = "ecs"
    }
  }

  environment = []
  secrets     = []
}
