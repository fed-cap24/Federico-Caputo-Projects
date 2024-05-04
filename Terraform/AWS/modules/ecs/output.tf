output "id"{
    value       = aws_ecs_cluster.ecs_cluster.id
    description = "ID of the ECS Cluster"
}

output "vpc"{
    value       = var.bastion_host.vpc
    description = "Output the current VPC so other modules have access to the same vpc"
}