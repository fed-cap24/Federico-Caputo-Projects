# AWS Terraform

## Overview

This project is a Terraform-based infrastructure as code (IaC) solution designed to deploy and manage various AWS resources using modular Terraform modules. The project is structured to ensure scalability, maintainability, and adherence to best practices.

## Folder Structure

The project is organized into the following main directories:

- `modules/`: This directory contains all the Terraform modules used in the project. Each module is designed to be reusable and encapsulates the creation of specific AWS resources.
- `root folders`: Each directory holds a sample of how to use the modules to deploy a particular Solution for AWS

### Modules

Within the `modules/` directory, you'll find the following modules, each with its own `readme.md` file for detailed documentation:

1. `vpc/`: Provisions a Virtual Private Cloud (VPC) with public and private subnets, and other necessary networking components.
2. `alb/`: Sets up an Application Load Balancer (ALB) to distribute incoming traffic across multiple ECS tasks or EC2 instances.
3. `bastion_host/`: Deploys a Bastion Host for secure SSH access to instances within the VPC.
4. `ecs/`: Creates an ECS cluster to run containerized applications.
5. `ecs_service/`: Manages the ECS service, including task definitions, services, and load balancer configurations.
6. `container_definitions/`: Define container definitions, formats it for JSON encoding, and sets up a CloudWatch log group for the container.

Each module's `readme.md` file provides detailed information on the module's purpose, components, how it works, usage instructions, and outputs.

### Root folders

1. `ECS-Sample`: Sets up a demo ECS cluster running an nginx aplication, with a load balancer

Each Root folder's `readme.md` file provides detailed information on the usage and module requirements.

## Usage

To use this project, you need to have Terraform installed and configured with the necessary AWS credentials. Clone the repository and navigate to the project directory. Then, initialize Terraform with `terraform init`, plan the deployment with `terraform plan`, and apply the changes with `terraform apply`.

For detailed instructions on how to use each module, refer to the individual `readme.md` files within the `modules/` directory.