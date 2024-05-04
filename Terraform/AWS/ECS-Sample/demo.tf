variable "demo_tags"{
    type = map(string)
  default = {
    environment = "demo",
    application = "demoApp"
  }
}

# Create a demo VPC
module "demo_vpc" {
    source   = "./modules/vpc"
    tags     = var.demo_tags
}

# Create a Load Balancer for the VPC

module "demo_alb" {
    source            = "./modules/alb"
    tags              = var.demo_tags
    vpc               = module.demo_vpc
    alb_sg            = [aws_security_group.http_https.id]
    target_groups     = module.demo_ECS_service.target_groups

    #You should make a litsener per {service_name}_{container name}_{port name}. by default, service_name is webserver, container name is ct and port_name is 80
    listeners = [{
      port = "80"
      protocol = "HTTP"
      default_action = {
        forward_target_group_arn = module.demo_alb.target_groups_arn["webserver_ct_80"]
      }
    }]
}

# Create a Bastion Host for the VPC

module "demo_bastion" {
    source            = "./modules/bastion_host"
    tags              = var.demo_tags
    vpc               = module.demo_vpc
    bastion_sg        = aws_security_group.bastion.id
    public_key        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs+j155hY8S6NLvG3gWGpY3TEdYcLGHMf8Sc6fqdUe5RHVHoD3l4kIdERLdfWHMcFe/F1brx0PJmiWTv++A5ZneS7f4bLT01faG65MBjM18BLUBET0zxv4hyjHxl8ebqCfQz9Mvj1iiximd5s42uKJev9qxA6IXo+tLZE9aKOhYqVN8sesrZRrGW0q3MtPDaYvz9cswkMU0Cjol1AJVMkVx9p9mQs0vTCKSTcrkUoNhyTmnPcaU+iVTRoTuWPfXpZD4QumEb0Z0Ez0tZGcRWvabDYtRArByljLITWDgdLUlAQ6uua8l4qwY+7E/Ej1Uxxl+NpLcD70CjOyvET2ekEn Feder@DESKTOP-1GM9R3C"
    private_key_path  = "./aws_sandbox_key"
}

# Create an ECS Cluster

module "demo_ECS_Cluster" {
    source        = "./modules/ecs"
    tags          = var.demo_tags
    bastion_host  = module.demo_bastion
    ec2_instance_role_profile_arn = aws_iam_instance_profile.ec2_instance_role_profile.arn

    auto_scaling = {
      min     = 1
      max     = 1
      desired = 1
    }
}

# Create an ECS service

module "demo_ECS_service"{
  source            = "./modules/ecs_service"
  tags              = var.demo_tags
  ecs_cluster       = module.demo_ECS_Cluster

  ecs_task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  #secret_credential = aws_secretsmanager_secret.hubmobeats.arn
  
  aws_region        = var.aws_region
  service = {
    security_groups = [module.demo_alb.lock_SGs["App"]]
  }

  target_groups_arn = module.demo_alb.target_groups_arn
}