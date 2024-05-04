resource "aws_cloudwatch_log_group" "ecs" {
  name = local.name-prefix != "" ? "${local.name-prefix}_${var.container_definition.name}_cw" : "${var.container_definition.name}_cw"
  retention_in_days = 30

  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_${var.container_definition.name}_ECS_Logs" : "${var.container_definition.name}_ECS_Logs" }
  )
  lifecycle {
    create_before_destroy = true
  }
}