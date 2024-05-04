variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

locals {
  # This local value constructs a prefix for resource names based on the presence of
  # 'application' and 'environment' tags. If both are present, it combines them with a hyphen.
  # If only one is present, it uses that value. If neither is present, it defaults to an empty string.
  name-prefix = lookup(var.tags, "application", "") != "" && lookup(var.tags, "environment", "") != "" ? "${lookup(var.tags, "application")}_${lookup(var.tags, "environment")}" : lookup(var.tags, "application", "") != "" ? lookup(var.tags, "application") : lookup(var.tags, "environment", "")
  name-posfix = local.name-prefix != "" ? "_${local.name-prefix}" : ""
  name-prefix-with-hyphen = lookup(var.tags, "application", "") != "" && lookup(var.tags, "environment", "") != "" ? "${lookup(var.tags, "application")}-${lookup(var.tags, "environment")}" : lookup(var.tags, "application", "") != "" ? lookup(var.tags, "application") : lookup(var.tags, "environment", "")
}

locals {
  container_definition  = {
    name         = "${var.container_definition.name}"
    image        = "${var.container_definition.image}"
    
    command      = var.container_definition.command

    repositoryCredentials = var.container_definition.secret_credential != null && var.container_definition.secret_credential != "" ? {
        credentialsParameter = var.container_definition.secret_credential
      } : null
    cpu          = var.container_definition.cpu
    memory       = var.container_definition.memory
    essential    = true
    portMappings = [for pm in var.container_definition.portMappings : {
          containerPort = pm.containerPort
          hostPort      = pm.hostPort
          protocol      = pm.protocol
        }]

    logConfiguration = {
        logDriver = "awslogs",
        options   = {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
            "awslogs-region"        = var.container_definition.aws_region,
            "awslogs-stream-prefix" = "app"
            }
    }

    environment = [for k, v in var.container_definition.environment_vars : {
        name  = k
        value = v
    }]

    mountPoints = var.container_definition.volume_container_path != null ? [{
      sourceVolume    = var.container_definition.name
      container_path  = var.container_definition.volume_container_path
    }] : []

    healthCheck     =   {
                command     = var.container_definition.healthCheck.command
                interval    = var.container_definition.healthCheck.interval
                timeout     = var.container_definition.healthCheck.timeout
                startPeriod = var.container_definition.healthCheck.startPeriod
                retries     = var.container_definition.healthCheck.retries
    }
  }
}
variable "container_definition" {
  type = object({
    name             = optional(string, "ct")
    image            = optional(string, "nginx:1.20-alpine")
    command          = optional(list(string),[])
    secret_credential = optional(string)
    cpu              = optional(number,  512)
    memory           = optional(number,  512)

    portMappings     = optional(map(object({
      containerPort   = optional(number,  80)
      hostPort        = optional(number,  80)
      protocol        = optional(string, "tcp")
    })),{
    TG = {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
    })

    aws_region        = string
    environment_vars  = optional(map(string), {})

    volume_container_path = optional(string)

    healthCheck       = optional(object({
      command         = optional(list(string), ["CMD-SHELL","exit  0"])
      interval        = optional(number,  60)
      timeout         = optional(number,  10)
      startPeriod     = optional(number,  30)
      retries         = optional(number,  3)
    }), {
      command         = ["CMD-SHELL","exit   0"]
      interval        =  60
      timeout         =  10
      startPeriod     =  30
      retries         =  3
    })
  })

  default = {
    name             = "ct"
    image            = "nginx:1.20-alpine"
    command          = []
    cpu              =  512
    memory           =  512

    portMappings     = {
      TG = {
        containerPort   =  80
        hostPort        =  80
        protocol        = "tcp"
      }
    }

    aws_region        = ""
    environment_vars  = {}

    healthCheck       = {
      command         = ["CMD-SHELL","exit  0"]
      interval        =  60
      timeout         =  10
      startPeriod     =  30
      retries         =  3
    }
  }
}
variable "network_mode"{
  description = "Network Mode used by the ECS Task Definition"
  type = string

  validation {
    condition     = contains(["bridge", "host", "awsvpc"], var.network_mode)
    error_message = "The network mode must be one of 'bridge', 'host' or 'awsvpc'."
  }
}