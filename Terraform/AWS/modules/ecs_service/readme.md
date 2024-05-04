# ECS Service Module

## Overview

This Terraform module provides a reusable and modular approach to provisioning and managing ECS (Elastic Container Service) services on Amazon Web Services (AWS). The module is designed to simplify the deployment and maintenance of ECS services by encapsulating the creation of various ECS components such as task definitions, services, and load balancer configurations.

## Components

The module consists of several Terraform files, each responsible for a specific aspect of the ECS service infrastructure:

- `variables.tf`: Defines the input variables that the module requires, such as tags, ECS cluster, and target groups.
- `ecs_service.tf`: Provisions the ECS service, including the task definition, service configuration, and load balancer integration.
- `task_definition.tf`: Defines the task definition for the ECS service, including container definitions and resource requirements.
- `output.tf`: Outputs the configuration of the ECS service and target groups for use in other modules or for further configuration.

### Modules
- `container_definitions`: Define container definitions, formats it for JSON encoding, and sets up a CloudWatch log group for the container.
## How It Works

### Input Variables

The module accepts input variables that allow customization of the ECS service infrastructure. These include:

- `tags`: A map of tags to apply to all resources created by the module.
- `ecs_cluster`: The ECS cluster configuration, including the cluster ID and VPC settings.
- `service`: Service definitions.
- `task_definition`: Task definition used by service. Includes the task Network mode, Memory usage and CPU usage.
- `container_definitions`: A map of different containers definitions used in the task definition.
- `target_groups_arn`: A map of target group ARNs generated by the load balancer module.
- `ecs_task_execution_role_arn`: ARN of the ECS Task Execution Role.


### Task Definition and Service Configuration

The module dynamically generates a task definition based on the provided container definitions and resource requirements. It then creates an ECS service that uses this task definition, integrating with the specified target groups for load balancing.

### Load Balancer Integration

The module configures the ECS service to use the specified target groups for load balancing. This allows the service to distribute incoming traffic across multiple tasks, improving availability and scalability.

## Usage

To use this module, include it in your Terraform configuration and provide the necessary input variables. Here's a short example of how to call the module:

```hcl
module "ecs_service" {
 source = "./modules/ecs_service"

 tags = {
    environment = "Production"
    application = "MyApp"
 }

 ecs_task_execution_role_arn = "my-ecs-task-execution-role-arn"

 ecs_cluster = module.ecs_cluster

 service = {
    name = "webserver"
    initial_desired_count = 1
    deployment_minimum_healthy_percent  = 100
    deployment_maximum_percent          = 200
    security_groups                     = []
 }

 task_definition = {
    network_mode  = "awsvpc"
    cpu           =  512
    memory        =  512
  }

 container_definitions = {
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
  }
 }

 target_groups_arn = module.alb.target_groups_arn
}
```

After configuring the module, run `terraform init` to initialize the backend and download the necessary providers. Then, execute `terraform plan` to preview the changes, and finally, `terraform apply` to create the ECS service infrastructure.

## Outputs

The module outputs the configuration of the ECS service and target groups, which can be used as inputs to other modules or for further configuration.

- `target_groups`: A map of target group configurations for use in ALB to make the target groups.
- `vpc`: The current VPC configuration, allowing other modules to access the same VPC.