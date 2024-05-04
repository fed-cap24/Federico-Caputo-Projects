# This locals tries to distribute the CPU and memory of non specified containers evenly, from the task definition
locals {
  # Calculate the total CPU and memory required for all containers
  total_cpu_requested    = sum([for def in var.container_definitions : def.cpu != null ? def.cpu :  0])
  total_memory_requested = sum([for def in var.container_definitions : def.memory != null ? def.memory :  0])

  # Calculate the remaining CPU and memory after accounting for the defined container definitions
  remaining_cpu    = var.task_definition.cpu - local.total_cpu_requested
  remaining_memory = var.task_definition.memory - local.total_memory_requested

  # Calculate the number of containers that do not have CPU defined
  undefined_containers_cpu = [for def in var.container_definitions : def if def.cpu == null]
  num_undefined_containers_cpu = length(local.undefined_containers_cpu)

  # Calculate the number of containers that do not have memory defined
  undefined_containers_memory = [for def in var.container_definitions : def if def.memory == null]
  num_undefined_containers_memory = length(local.undefined_containers_memory)

  # Calculate the average CPU and memory per undefined container
  average_cpu    = local.remaining_cpu / local.num_undefined_containers_cpu
  average_memory = local.remaining_memory / local.num_undefined_containers_memory
}

module "containers" {
  source = "git::https://github.com/fed-cap24/Federico-Caputo-Projects/tree/main/Terraform/AWS/modules/container_definitions"
  network_mode  = var.task_definition.network_mode
  tags          = var.tags

  for_each = var.container_definitions

  # Pass the container definition to the module
  container_definition = {
    name = "${var.service.name}_${each.key}"
    image = each.value.image

    command = each.value.command

    # Use the defined values if available, otherwise use the average values
    cpu     = each.value.cpu != null ? each.value.cpu : local.average_cpu
    memory  = each.value.memory != null ? each.value.memory : local.average_memory

    portMappings = each.value.portMappings

    # Use the default values if not defined in the container definition
    secret_credential = each.value.secret_credential != null ? each.value.secret_credential : var.secret_credential
    aws_region        = var.aws_region

    environment_vars = each.value.environment_vars

    volume_container_path = each.value.volume != null ? each.value.volume.container_path : null

    healthCheck = each.value.healthCheck
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = local.name-prefix != "" ? "${local.name-prefix}_${var.service.name}" : var.service.name
  task_role_arn            = var.ecs_task_execution_role_arn
  execution_role_arn       = var.ecs_task_execution_role_arn
  requires_compatibilities = ["EC2"]
  network_mode             = var.task_definition.network_mode
  cpu                      = var.task_definition.cpu
  memory                   = var.task_definition.memory
  container_definitions    = jsonencode([for container in module.containers : container.container_definition])

  dynamic "volume" {
    for_each = { for def in var.container_definitions : def.key => def if def.volume != null }
    content {
      name = "${var.service.name}_${each.key}"
      docker_volume_configuration {
        scope         = "shared"
        autoprovision = true
        driver        = "rexray/ebs"
        driver_opts   = def.driver_opts 
      }
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_${var.service.name}" : var.service.name }
  )
}