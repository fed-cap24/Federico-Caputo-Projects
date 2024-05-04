locals {
  all_targets = merge([
    for container_name, container in var.container_definitions:
    {
      for port_name, port in container.portMappings :
      "${var.service.name}_${container_name}_${port_name}" => {
        container_name = "${var.service.name}_${container_name}"
        container_port = port.containerPort
        TG_protocol = port.TG_protocol

        TG_healthCheck = port.TG_healthCheck
      }
    }
  ]...)
}

## Creates ECS Service

resource "aws_ecs_service" "service" {
  name                               = local.name-prefix != "" ? "${local.name-prefix}_${var.service.name}" : var.service.name
  cluster                            = var.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.task.arn
  desired_count                      = var.service.initial_desired_count
  deployment_minimum_healthy_percent = var.service.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.service.deployment_maximum_percent
  scheduling_strategy                = "REPLICA"

  dynamic "network_configuration" {
    for_each = var.task_definition.network_mode == "awsvpc" ? [1] : []
    content {
      subnets         = var.ecs_cluster.vpc.private_subnet
      security_groups = var.service.security_groups
    }
  }

  dynamic "load_balancer" {
    for_each = local.all_targets
    content {
      target_group_arn = var.target_groups_arn[load_balancer.key]
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  ## Spread tasks evenly accross all Availability Zones for High Availability
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  
  ## Make use of all available space on the Container Instances
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  ## Do not update desired count again to avoid a reset to this number on every deployment
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(
    var.tags,
    {Name = local.name-prefix != "" ? "${local.name-prefix}_${var.service.name}" : var.service.name}
  )
}