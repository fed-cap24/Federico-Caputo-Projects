# ECS-Modular-Plantilla Project

## Overview

The ECS-Modular-Plantilla project is a Terraform-based infrastructure as code (IaC) solution designed to demonstrate the deployment and management of an ECS (Elastic Container Service) environment on Amazon Web Services (AWS). This project showcases the use of modular Terraform modules to provision and manage various AWS resources, including VPCs, Application Load Balancers (ALBs), Bastion Hosts, and ECS services, in a structured and reusable manner. The primary goal is to provide a comprehensive example of how to deploy an Nginx application using a modular approach, ensuring scalability, maintainability, and best practices.

## Components

The project is composed of several Terraform modules, each responsible for a specific aspect of the infrastructure:

- **VPC Module**: Provisions a Virtual Private Cloud (VPC) with public and private subnets, and other necessary networking components.
- **ALB Module**: Sets up an Application Load Balancer (ALB) to distribute incoming traffic across multiple ECS tasks or EC2 instances.
- **Bastion Host Module**: Deploys a Bastion Host for secure SSH access to instances within the VPC.
- **ECS Cluster Module**: Creates an ECS cluster to run containerized applications.
- **ECS Service Module**: Manages the ECS service, including task definitions, services, and load balancer configurations.
- **IAM**: Configures IAM roles and policies required for ECS and other AWS services.
- **Security Groups**: Defines security groups for network traffic control.
- **Secrets Manager**: Manages secrets for secure storage and access.
- **Variables**: Variables to be used across the entire project. This includes: aws_region, aws_profile, project-tags, and secret configuration.
- **provieder**: provieder configuration. Note that aws_region must be set up here too for the backend S3 bucket holding the TF state.

## How It Works

The project uses a modular approach, where each module is responsible for a specific part of the infrastructure. The modules are designed to be reusable and can be combined to create complex environments. The modules interact with each other through outputs and inputs, allowing for a clear separation of concerns and easy customization.

### VPC

The VPC module creates a VPC with public and private subnets, security groups, and other networking components. It also sets up CloudWatch log groups for VPC flow logs and IAM roles and policies for VPC flow logs to publish to CloudWatch log groups.

### ALB

The ALB module provisions an ALB with listeners and target groups, integrating with the VPC and security groups. It also configures security groups for the ALB to control inbound and outbound traffic.

### Bastion Host

The Bastion Host module deploys a Bastion Host within the VPC, providing secure SSH access to instances. It includes security group configurations to allow access from approved locations.

### ECS Cluster

The ECS Cluster module creates an ECS cluster, which is a logical grouping of tasks or services. It also sets up IAM roles and policies for the ECS agent and EC2 instances.

### ECS Service

The ECS Service module manages the ECS service, including task definitions, services, and load balancer configurations. It integrates with the VPC and ALB modules to ensure proper networking and load balancing.

### IAM

The IAM configures IAM roles and policies for ECS, EC2 instances, and other AWS services. It includes roles for the ECS agent, EC2 instances, and ECS task execution.

### Security Groups

The Security Groups defines security groups for network traffic control, including rules for SSH access to the Bastion Host and HTTP/HTTPS access to the ALB.

### Secrets Manager

The Secrets Manager manages secrets for secure storage and access, such as database credentials or API keys.

## Usage

To use this project, you need to have Terraform installed and configured with the necessary AWS credentials. Clone the repository and navigate to the project directory. Then, initialize Terraform with `terraform init`, plan the deployment with `terraform plan`, and apply the changes with `terraform apply`.


Here's a short example of how to call the modules in the root Terraform configuration file:


```hcl
module "demo_vpc" {
 source   = "./modules/vpc"
 tags     = var.demo_tags
}

module "demo_alb" {
 source            = "./modules/alb"
 tags              = var.demo_tags
 vpc               = module.demo_vpc
 alb_sg            = [aws_security_group.http_https.id]
 target_groups     = module.demo_ECS_service.target_groups
 listeners        = [{
    port = "80"
    protocol = "HTTP"
    default_action = {
      forward_target_group_arn = module.demo_alb.target_groups_arn["webserver_ct_80"]
    }
 }]
}

module "demo_bastion" {
 source            = "./modules/bastion_host"
 tags              = var.demo_tags
 vpc               = module.demo_vpc
 bastion_sg        = aws_security_group.bastion.id
 public_key        = "{YOUR-PUBLIC-KEY}"
 private_key_path = "{YOUR-PRIVATE-KEY-LOCATION}"
}


module "demo_ECS_Cluster" {
 source        = "./modules/ecs"
 tags          = var.demo_tags
 bastion_host = module.demo_bastion
 ec2_instance_role_profile_arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
 auto_scaling = {
    min     = 1
    max     = 1
    desired = 1
 }
}

module "demo_ECS_service" {
 source            = "./modules/ecs_service"
 tags              = var.demo_tags
 ecs_cluster       = module.demo_ECS_Cluster
 ecs_task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
 aws_region        = var.aws_region
 service = {
    security_groups = [module.demo_alb.lock_SGs["App"]]
 }
 target_groups_arn = module.demo_alb.target_groups_arn
}
```

Here is an extended example making use of most capabilities:

```hcl
module "demo_vpc" {
 source   = "./modules/vpc"
 tags     = var.demo_tags
}

module "demo_alb" {
 source            = "./modules/alb"
 tags              = var.demo_tags
 vpc               = module.demo_vpc
 alb_sg            = [aws_security_group.http_https.id]
 target_groups     = module.demo_ECS_service.target_groups
 listeners        = [{
    port = "80"
    protocol = "HTTP"
    default_action = {
      forward_target_group_arn = module.demo_alb.target_groups_arn["webserver_ct_80"]
    }
    rules = [
        {
            action = {
                forward_target_group_arn = "example arn"
            }
            condition = {
                host_header = ["subdomain.example.com"]
            }
        }
    ]
 }]

 lock_security_groups = {
    App = {
      description = "Lock security group for port 80"
      ingress = [
        {
          from_port = 80
          to_port   = 80
          protocol  = "tcp"
          description = "Allow access to port 80"
        }
      ]
    }
 }
}

module "demo_bastion" {
 source            = "./modules/bastion_host"
 tags              = var.demo_tags
 vpc               = module.demo_vpc
 bastion_sg        = aws_security_group.bastion.id
 public_key        = "{YOUR-PUBLIC-KEY}"
 private_key_path = "{YOUR-PRIVATE-KEY-LOCATION}"
}


module "demo_ECS_Cluster" {
 source        = "./modules/ecs"
 tags          = var.demo_tags
 bastion_host = module.demo_bastion
 ec2_instance_role_profile_arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
 auto_scaling = {
    ec2 = {
        type = "t3.micro"
        user_data = <<-EOF
        #!/bin/bash
        echo ECS_CLUSTER=${local.ECS-cluster-name} >> /etc/ecs/ecs.config
        echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
        echo ECS_LOGFILE=/var/log/ecs/ecs-agent.log >> /etc/ecs/ecs.config
        echo ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]' >> /etc/ecs/ecs.config
        echo ECS_LOGLEVEL=info >> /etc/ecs/ecs.config

        # Other user_data require for instances

        EOF
    }
    min     = 1
    max     = 1
    desired = 1
 }
}

module "demo_ECS_service" {
 source            = "./modules/ecs_service"
 tags              = var.demo_tags
 ecs_cluster       = module.demo_ECS_Cluster
 ecs_task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
 service = {
    name = "webserver"
    initial_desired_count = 1
    deployment_minimum_healthy_percent  = 100
    deployment_maximum_percent          = 200
    security_groups = [module.demo_alb.lock_SGs["App"]]
 }

 task_definition = {
    network_mode  = "awsvpc"
    cpu           =  512
    memory        =  512
  }
 
 container_definitions = {
  ct = {
    image            = "nginx:1.20-alpine"
    cpu              = 256
    memory           = 256
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

    environment_vars  = {
        VARNAME = "VARVAL"
    }

    healthCheck       = {
      command         = ["CMD-SHELL","exit  0"]
      interval        =  60
      timeout         =  10
      startPeriod     =  30
      retries         =  3
    }  
  }
  }

 target_groups_arn = module.demo_alb.target_groups_arn
}
```

After configuring the modules, run `terraform init` to initialize the backend and download the necessary providers. Then, execute `terraform plan` to preview the changes, and finally, `terraform apply` to create the infrastructure.


## Outputs

The project outputs the configuration of the ECS service and target groups, which can be used as inputs to other modules or for further configuration. It also outputs the IDs and ARNs of the created resources, which can be used for monitoring, troubleshooting, and management purposes.


### VPC

- `id`: The ID of the VPC.
- `public_subnet`: A list of the IDs of the public subnets.
- `private_subnet`: A list of the IDs of the private subnets.


### ALB

- `target_groups_arn`: A map of target group ARNs for use in other modules.
- `lock_SGs`: A map of security group IDs for use in other modules.


### ECS Service

- `target_groups`: A map of target group configurations for use in ALB to make the target groups.
- `vpc`: The current VPC configuration, allowing other modules to access the same VPC.


### IAM

- `ecs_agent`: The ARN of the ECS agent IAM role.
- `ec2_instance_role`: The ARN of the EC2 instance IAM role.
- `ecs_task_execution_role`: The ARN of the ECS task execution IAM role.


### Security Groups

- `bastion`: The ID of the Bastion Host security group.
- `http_https`: The ID of the HTTP/HTTPS security group.


### Secrets Manager

- `hubmobeats`: The ARN of the secret for the Nginx application credentials.


## Conclusion

This project demonstrates a modular approach to deploying an Nginx application on AWS using ECS. It showcases the use of Terraform modules to create a scalable and maintainable infrastructure, with each module encapsulating a specific aspect of the infrastructure. By using this project as a template, you can quickly set up and manage complex ECS environments with ease.