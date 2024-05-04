# ECS Cluster Module
## Overview

This Terraform module provides a reusable and modular approach to provisioning and managing an Elastic Container Service (ECS) cluster on Amazon Web Services (AWS). The module is designed to simplify the deployment and maintenance of ECS clusters by encapsulating the creation of various ECS components such as clusters, launch templates, auto-scaling groups, and more.

## Components

The module consists of several Terraform files, each responsible for a specific aspect of the ECS cluster infrastructure:

- `variables.tf`: Defines the input variables that the module requires, such as tags, VPC configuration, and auto-scaling settings.
- `ecs.tf`: Provisions the core ECS resources, including the ECS cluster, launch template, and auto-scaling group.
- `bastion_host.tf`: Creates a public and private key pair for secure SSH access to the ECS instances via a bastion host.

## How It Works

### Input Variables

The module accepts input variables that allow customization of the ECS cluster infrastructure. These include:

- `tags`: A map of tags to apply to all resources created by the module.
- `auto_scaling`: Auto-scaling configuration for the ECS cluster, including instance type, user data, and desired, minimum, and maximum instance counts.
- `bastion_host`: Configuration for the bastion host, including its Elastic IP, user, private key path, security group ID and vpc.
- `ec2_instance_role_profile_arn`: Instance Role ARN for the EC2 instances.
- `ec2_instance_sg`: Optional List of security groups to be added to the instance if needed.

### Naming Convention

The module generates a name-prefix to be used in all resources based on the tags of the application. If tags have an application and/or environment tag, it will add these to the names. This allows reusing the module in different applications and environments within the same account.

### Bastion Host

A bastion host is required for the module. It will then create a public and private key pair for secure SSH access to the ECS instances. The private key is stored on the bastion host and can be used to SSH into the ECS instances. The files are stored in ./ssh for ease of access to the ECS instances.

### ECS Cluster

An ECS cluster is provisioned with the generated name. The cluster is associated with the specified VPC and subnets.

### Launch Template

A launch template is created for the ECS instances, specifying the instance type, and user data. The user data script configures the ECS agent on the instances. By default, these instances are t3.micro.

### Auto-Scaling Group

An auto-scaling group is set up to manage the ECS instances, with the specified desired, minimum, and maximum instance counts. The auto-scaling group uses the launch template to launch new instances. By default, there will be a minimun capacity of 1, a desired capacity of 2 (only at launch), and a maximum capacity of 3.

### CloudWatch Logs

By default, the user data of the ECS cluster will configure the ECS agent to send logs to CloudWatch. The `awslogs` driver is enabled, allowing the ECS agent to stream logs to CloudWatch Logs. The log level is set to `info`, which means that informational messages, warnings, errors, and critical issues will be logged. The logs are written to `/var/log/ecs/ecs-agent.log`.

## Usage

To use this module, include it in your Terraform configuration and provide the necessary input variables. Here's a short example of how to call the module:

```hcl
module "ecs_cluster" {
  source = "./modules/ecs"

  tags = {
    environment = "Production"
    application = "MyApp"
  }

  auto_scaling = {
    ec2 = {
      type      = "t3.small"
    }
  }

  bastion_host = module.bastion_host
}
```

By default, auto_scaling is defined to use t3.micro instances, and configure the cloudwatch agent of the ECS instances. Also, it will set the autoscaling to a minimun of 1 and a maximum of 3. You can use this complete example of how to call the module:

```hcl
module "ecs_cluster" {
  source = "./modules/ecs"

  tags = {
    environment = "Production"
    application = "MyApp"
  }

  auto_scaling = {
    ec2 = {
      type       = "t3.micro"
      user_data  = <<-EOF
        #!/bin/bash
        echo ECS_CLUSTER=${local.ECS-cluster-name} >> /etc/ecs/ecs.config
        echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
        echo ECS_LOGFILE=/var/log/ecs/ecs-agent.log >> /etc/ecs/ecs.config
        echo ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]' >> /etc/ecs/ecs.config
        echo ECS_LOGLEVEL=info >> /etc/ecs/ecs.config
        EOF
    }
    desired =   2
    min     =   1
    max     =   3
  }

  bastion_host = {
    public_ip         = "3.3.3.3"
    user              = "ec2-user"
    private_key_path  = "/path/to/private/key"
    sg_ecs_id         = "sg-abcdefgh"
    vpc = {
      id              = "vpc-abcdefgh"
      private_subnet  = ["subnet-abcdefgh", "subnet-ijklmnop"]
      public_subnet   = ["subnet-qrstuvwx", "subnet-yzabcdef"]
    }
  }
}
```

After configuring the module, run `terraform init` to initialize the backend and download the necessary providers. Then, execute `terraform plan` to preview the changes, and finally, `terraform apply` to create the ECS cluster infrastructure.

## Outputs

The module outputs the following attributes:

- **id**: The ID of the ECS cluster.
- **vpc**: The current vpc of the ECS cluster, for future use.