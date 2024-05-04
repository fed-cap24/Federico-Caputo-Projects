output "target_groups" {
  description = "Map of {service_name}_{container name}_{port name} to their Target group configuration, for use in ALB to make the target groups"
  value = { for k,v in local.all_targets : k =>{
    port = v.container_port
    protocol = v.TG_protocol
    target_type = var.task_definition == "awsvpc" ? "instance" : "ip"

    healthCheck = v.TG_healthCheck
  }}
}

output "vpc"{
    value       = var.ecs_cluster.vpc
    description = "Output the current VPC so other modules have access to the same vpc"
}