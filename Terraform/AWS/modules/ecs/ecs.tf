resource "aws_ecs_cluster" "ecs_cluster" {
    name  = local.ECS-cluster-name
}

## Get most recent AMI for an ECS-optimized Amazon Linux 2 instance

data "aws_ami" "amazon_linux_2_ecs" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

## Launch template for all EC2 instances that are part of the ECS cluster

resource "aws_launch_template" "ecs_launch_template" {
  name                   = local.name-prefix != "" ? "ECS_Launch_Template_${local.name-prefix}" : "ECS_Launch_Template"
  image_id               = data.aws_ami.amazon_linux_2_ecs.id
  instance_type          = var.auto_scaling.ec2.type
  key_name               = aws_key_pair.ecs.key_name
  user_data              = base64encode(local.auto_scaling_user_data)
  vpc_security_group_ids = flatten([var.bastion_host.sg_bastion_access_id,var.ec2_instance_sg])

  iam_instance_profile {
    arn = var.ec2_instance_role_profile_arn
  }

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {

  name                      = local.name-prefix != "" ? "ASG_${local.name-prefix}" : "ASG"
  vpc_zone_identifier       = var.bastion_host.vpc.private_subnet

  desired_capacity          = var.auto_scaling.desired
  min_size                  = var.auto_scaling.min
  max_size                  = var.auto_scaling.max
  health_check_grace_period = 300
  health_check_type         = "EC2"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = local.name-prefix != "" ? "ECS_Instance_${local.name-prefix}" : "ECS"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}