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
}

variable "secret_credential" {
  description = "Optional variable. It will default all containers definitions to this value of the secret_credential if the container definition secret_credential is not defined"
  type    = string
  default = ""
}

variable "aws_region"{
  description = "Optional variable. It will default all containers definitions to this value of the aws_region if the container definition aws_region is not defined"
  type    = string
  default = ""
}

variable "service"{
  type  = object({
    name                  = optional(string,"webserver")
    initial_desired_count = optional(number,1)
    deployment_minimum_healthy_percent = optional(number,100)
    deployment_maximum_percent         = optional(number,200)
    security_groups                    = optional(list(string),[])
  })

  default = {
    name = "webserver"
    initial_desired_count = 1
    deployment_minimum_healthy_percent  = 100
    deployment_maximum_percent          = 200
    security_groups                     = []
  }
}

variable "task_definition" {
  type  = object({
    network_mode  = optional(string,"awsvpc")
    cpu           = optional(number, 512)
    memory        = optional(number, 512)
  })

  default = {
    network_mode  = "awsvpc"
    cpu           =  512
    memory        =  512
  }

  validation {
    condition     = contains(["bridge", "host", "awsvpc"], var.task_definition.network_mode)
    error_message = "The network mode must be one of 'bridge', 'host' or 'awsvpc'."
  }
}

variable "container_definitions" {
  type = map(object({
    image            = string
    secret_credential= optional(string)
    cpu              = optional(number)
    memory           = optional(number)

    command          = optional(list(string),[])

    portMappings     = optional(map(object({
      containerPort   = optional(number,  80)
      hostPort        = optional(number,  80)
      protocol        = optional(string, "tcp")

      TG_protocol     = optional(string, "HTTP")

      TG_healthCheck  = optional(object({
        interval       = optional(number,  60)
        path           = optional(string, "/")
        port           = optional(number, -1)
        protocol       = optional(string, "HTTP")
        timeout        = optional(number,  30)
        healthy_threshold = optional(number,  3)
        unhealthy_threshold = optional(number,  2)
        matcher        = optional(string, "200-299")
      }), {
        interval = 60
        path     = "/"
        port     = -1
        protocol = "HTTP"
        timeout  = 30
        healthy_threshold = 3
        unhealthy_threshold = 2
        matcher = "200-299"
      })
    })),{
      80 = {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"

      TG_protocol = "HTTP"

      TG_healthCheck = {
        interval       = 60
        path           = "/"
        port           = -1
        protocol       = "HTTP"
        timeout        = 30
        healthy_threshold = 3
        unhealthy_threshold = 2
        matcher        = "200-299"
      }
    }})
    environment_vars  = optional(map(string), {})

    volume = optional(object({
      container_path = string
      driver_opts = optional(object({
        volumetype = string
        size       = number
      }))
    }))

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
  }))
  default = {
  ct = {
    image            = "nginx:1.20-alpine"

    portMappings     = {
      80 = {
        containerPort   =  80
        hostPort        =  80
        protocol        = "tcp"

        TG_protocol = "HTTP"

        TG_healthCheck = {
          interval       = 60
          path           = "/"
          port           = -1
          protocol       = "HTTP"
          timeout        = 30
          healthy_threshold = 3
          unhealthy_threshold = 2
          matcher        = "200-299"
        }
      }
    }

    environment_vars  = {}

    healthCheck       = {
      command         = ["CMD-SHELL","exit  0"]
      interval        =  60
      timeout         =  10
      startPeriod     =  30
      retries         =  3
    }  
  }}
}

variable "ecs_cluster"{
  description = "ECS cluster"
  type = object({
    id        = string
    vpc = object({
      id              = string
      private_subnet  = list(string)
      public_subnet   = list(string)
    })
  })
}

variable "target_groups_arn" {
  description = "Map of target group arn. It must at least contain the matching {service_name}_{container_name}_{port_name} keys to the arn"
  type = map(string)
  default = {}
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  type    = string
}