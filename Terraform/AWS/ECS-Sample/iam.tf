#IAM Role for ECS Service

resource "aws_iam_role" "ecs_agent" {
  name               = var.project-tags.project != null && var.project-tags.project != "" ? "ECS_Agent_${var.project-tags.project}" : "ECS_Agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com",]
    }
  }
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = var.project-tags.project != null && var.project-tags.project != "" ? "ECS_Agent_${var.project-tags.project}_RolePolicy" : "ECS_Agent_RolePolicy"
  policy = data.aws_iam_policy_document.ecs_service_role_policy.json
  role   = aws_iam_role.ecs_agent.id
}

data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:DescribeTags",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutSubscriptionFilter",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

## Creates IAM Role which is assumed by the Container Instances (aka EC2 Instances)

resource "aws_iam_role" "ec2_instance_role" {
  name               = var.project-tags.project != null && var.project-tags.project != "" ? "EC2_InstanceRole_${var.project-tags.project}" : "EC2_InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# IAM Policy for EC2 instances to describe EBS volumes
resource "aws_iam_policy" "ec2_describe_volumes" {
  name        = "EC2DescribeVolumes"
  description = "Allow ECS instances to describe EBS volumes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:DescribeVolumes"
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_describe_volumes.arn
}

resource "aws_iam_instance_profile" "ec2_instance_role_profile" {
  name  = var.project-tags.project != null && var.project-tags.project != "" ? "EC2_InstanceRoleProfile_${var.project-tags.project}" : "EC2_InstanceRoleProfile"
  role  = aws_iam_role.ec2_instance_role.id
}

data "aws_iam_policy_document" "ec2_instance_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}

## ECS Task Execution Role

resource "aws_iam_role" "ecs_task_execution_role" {
  name = var.project-tags.project != null && var.project-tags.project != "" ? "ECS_TaskExecutionRole_${var.project-tags.project}" : "ECS_TaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_taskRolePolicy.json
}

data "aws_iam_policy_document" "ecs_taskRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_taskPolicy"{
  statement {
    sid    = "CloudWatchPolicy"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPolicy"
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSPolicy"
    effect = "Allow"
    actions = [
      "ecs:CreateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:ListContainerInstances",
      "ecs:StopTask",
      "ecs:DescribeTasks",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DeregisterTaskDefinition",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SSMPolicy"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "KMSPolicy"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
  }

  statement {
    sid   = "SecretManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "ecs_policy" {
  name   = var.project-tags.project != null && var.project-tags.project != "" ? "ECS_Policy_${var.project-tags.project}" : "ECS_Policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ecs_taskPolicy.json
}

# Attach ecs Role and Policy
resource "aws_iam_role_policy_attachment" "ecs_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}