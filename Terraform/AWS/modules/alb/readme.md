# Application Load Balancer (ALB) Module

## Overview

This Terraform module provides a reusable and modular approach to provisioning and managing Application Load Balancers (ALBs) on Amazon Web Services (AWS). The module is designed to simplify the deployment and maintenance of ALB infrastructure by encapsulating the creation of various ALB components such as listeners, target groups, and security groups.

## Components

The module consists of several Terraform files, each responsible for a specific aspect of the ALB infrastructure:

- `variables.tf`: Defines the input variables that the module requires, such as tags, VPC configuration, and listener settings.
- `alb.tf`: Provisions the Application Load Balancer, including its configuration and integration with security groups.
- `listeners.tf`: Defines the listeners for the ALB, including their settings and default actions.
- `target_group.tf`: Creates the target groups for the ALB, including their health check configurations.
- `security_groups.tf`: Sets up security groups for the ALB, including ingress and egress rules.
- `output.tf`: Outputs the configuration of the ALB and target groups for use in other modules or for further configuration.

## How It Works

### Input Variables

The module accepts input variables that allow customization of the ALB infrastructure. These include:

- `tags`: A map of tags to apply to all resources created by the module.
- `internal`: A boolean flag to determine if the ALB is internal or internet-facing.
- `alb_sg`: List of security groups to allow access to the Application Load Balancer.
- `vpc`: The VPC configuration for the ALB, including the VPC ID and subnet IDs.
- `listeners`: A set of listener configurations for the ALB, including port, protocol, and default actions.
- `target_groups`: A map of target group configurations for the ALB, including port, protocol, and health check settings.
- `lock_security_groups`: A map of security groups with ingress rules from the ALB.

### Listener Configuration

The module configures listeners for the ALB based on the provided settings. Each listener can have a default action and optional rules for routing traffic.

### Target Group Configuration

The module creates target groups for the ALB, which are used to route requests to one or more registered targets, such as ECS tasks or EC2 instances.

### Security Group Configuration

The module sets up security groups for the ALB, which control inbound and outbound traffic to the ALB. This security groups allow only traffic from the ALB, to the ALB.
If the application requires outbound Access to the internet, or other resources that aren't the ALB, a secondary SG should be added to whichever element is using this, allowing that egress rule.

## Usage

To use this module, include it in your Terraform configuration and provide the necessary input variables. Here's a short example of how to call the module:

```hcl
module "alb" {
 source = "./modules/alb"

 tags = {
    environment = "Production"
    application = "MyApp"
 }

 internal = false

 vpc = {
    id              = "vpc-12345678"
    private_subnet = ["subnet-12345678", "subnet-23456789"]
    public_subnet   = ["subnet-34567890", "subnet-45678901"]
 }

 listeners = [
    {
      port        = "80"
      protocol    = "HTTP"
      default_action = {
        forward_target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
      }
    }
 ]

 target_groups = {
    "MyApp_webserver_80" = {
      port        = 80
      protocol    = "HTTP"
      target_type = "ip"
      healthCheck = {
        enabled             = true
        interval            = 60
        path                = "/"
        port                = -1
        protocol            = "HTTP"
        timeout             = 30
        healthy_threshold   = 3
        unhealthy_threshold = 2
        matcher             = "200-299"
      }
    }
 }

 lock_security_groups = {
    App = {
      description = "Lock security group for port 80"
      ingress = [
        {
          from_port = 80
          to_port   = 80
          protocol = "tcp"
          description = "Allow access to port 80"
        }
      ]
    }
 }
}
```

After configuring the module, run `terraform init` to initialize the backend and download the necessary providers. Then, execute `terraform plan` to preview the changes, and finally, `terraform apply` to create the ALB infrastructure.

## Outputs

The module outputs the configuration of the ALB and target groups, which can be used as inputs to other modules or for further configuration.

- `target_groups_arn`: A map of target group ARNs for use in other modules.
- `lock_SGs`: A map of security group IDs for use in other modules.