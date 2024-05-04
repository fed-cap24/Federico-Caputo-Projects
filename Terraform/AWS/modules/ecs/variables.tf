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
  ECS-cluster-name = local.name-prefix != "" ? "${local.name-prefix}_ECS_cluster" : "ECS_cluster"
  name-posfix = local.name-prefix != "" ? "_${local.name-prefix}" : ""
  auto_scaling_user_data = var.auto_scaling.ec2.user_data != "" ? var.auto_scaling.ec2.user_data : <<-EOF
        #!/bin/bash
        echo ECS_CLUSTER=${local.ECS-cluster-name} >> /etc/ecs/ecs.config
        echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
        echo ECS_LOGFILE=/var/log/ecs/ecs-agent.log >> /etc/ecs/ecs.config
        echo ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]' >> /etc/ecs/ecs.config
        echo ECS_LOGLEVEL=info >> /etc/ecs/ecs.config
        EOF
}

variable "bastion_host"{
  description = "Bastion host which will be able to connect to the AWS Instances"
  type        = object({
    public_ip             = string
    user                  = string
    private_key_path      = string
    sg_bastion_access_id  = string
    vpc                   = object({
      id              = string
      private_subnet  = list(string)
      public_subnet   = list(string)
    })
  })
}

variable "auto_scaling" {
  description = "Auto scaling configuration for the ECS cluster"
  type        = object({
    ec2 = optional(object({
      type        = optional(string,"t3.micro")
      user_data   = optional(string, "")
    }),{
      type       = "t3.micro"
      user_data  = ""
    })
    desired = optional(number,2)
    min     = optional(number,1)
    max     = optional(number,3)
  })
  default = {
    ec2 = {
      type       = "t3.micro"
      user_data  = ""
    }
    desired =   2
    min     =   1
    max     =   3
  }
}

variable "ec2_instance_role_profile_arn" {
  description = "IAM Role which is assumed by the EC2 Instances"
  type        = string
}

variable "ec2_instance_sg"{
  description = "Optional Security groups if they need to be added to the EC2 instance"
  type    = list(string)
  default = []
}