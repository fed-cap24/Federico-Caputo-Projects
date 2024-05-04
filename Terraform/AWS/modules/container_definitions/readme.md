# Container Definitions Module

## Overview

This Terraform module is designed to manage container definitions for Amazon Elastic Container Service (ECS) tasks. It takes a container definition as input, formats it for JSON encoding, and sets up a CloudWatch log group for the container.

## Naming Convention

The module generates a name-prefix to be used in all resources based on the tags of the application. If tags have an application and/or environment tag, it will add these to the names. This allows reusing the module in different applications and environments in the same account.

## Components

The module consists of several Terraform files, each responsible for a specific aspect of the container definition and logging setup:

- `variables.tf`: Defines the input variables that the module requires, such as tags, container definition details, and AWS region.
- `output.tf`: Outputs the formatted container definition that can be used in an ECS task definition.
- `cloudwatch.tf`: Sets up a CloudWatch log group for the container, enabling monitoring and analysis of container logs.

## Input Variables

The module accepts input variables that allow customization of the container definition and logging setup. These include:

- `tags`: A map of tags to apply to all resources created by the module.
- `container_definition`: An object that defines the container's name, image, CPU, memory, port mappings, environment variables, and health check settings.
- `network_mode`: Network Mode used by the ECS Task Definition. Must be one of 'bridge', 'host' or 'awsvpc'.

## CloudWatch Logs

The module sets up a CloudWatch log group for the container. These logs capture information about the container's runtime, which can be useful for monitoring, troubleshooting, and security analysis. The log group is configured with a retention period of  30 days and is tagged with the `Name` tag derived from the `local.name-prefix`.

## Usage

To use this module, include it in your Terraform configuration and provide the necessary input variables. Here's a short example of how to call the module:

```hcl
module "container_definitions" {
  source = "./modules/ecs_service/modules/container_definitions"

  tags = {
    environment = "Production"
    application = "MyApp"
  }

  container_definition = {
    name  = "my-container"
    image = "my-image:latest"

    secret_credential = aws_secretsmanager_secret.hubmobeats.arn

    cpu   =  256
    memory =  512
    portMappings = [
      {
        containerPort =  80
        hostPort      =  80
        protocol      = "tcp"
      }
    ]
    environment_vars = {
      VAR_NAME = "value"
    }
    healthCheck = {
      command     = ["CMD-SHELL","curl -f http://localhost/ || exit  1"]
      interval    =  60
      timeout     =  10
      startPeriod =  30
      retries     =  3
    }
  }

  network_mode = "awsvpc"
}
```

By default, the settings are:

- **name**              = "container"
- **image**             = "nginx:1.20-alpine"
- **secret_credential** = ""
- **cpu**       =   512
- **memory**    =   512
- **portMappings** = [
    {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
    }]
- **aws_region** = ""
- **environment_vars** = {}
- **healthCheck** = {
        command     = ["CMD-SHELL","exit 0"] (always healthy)
        interval    = 60
        timeout     = 10
        startPeriod = 30
        retries     = 3
    }




After configuring the module, run `terraform init` to initialize the backend and download the necessary providers. Then, execute `terraform plan` to preview the changes, and finally, `terraform apply` to create the container definition and CloudWatch log group.

## Outputs

The module outputs the following attributes:

- `container_definition`: The formatted container definition that can be used in an ECS task definition.