output "container_definition"{
    value = local.container_definition
    description = "Outputs a container_definition in a format that can be jsonencode([module.name.container_definition]) in a task definition container_definitions"
}