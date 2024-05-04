resource "aws_lb_target_group" "tg" {
  for_each = var.target_groups

  name        = local.name-prefix != "" ? "${replace(local.name-prefix,"_","-")}-${replace(each.key,"_","-")}-TG" : "${replace(each.key,"_","-")}-TG" 
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc.id
  target_type = each.value.target_type

  health_check {
    enabled             =  each.value.healthCheck.enabled
    interval            =  each.value.healthCheck.interval
    path                =  each.value.healthCheck.path
    port                =  each.value.healthCheck.port == -1 ? "traffic-port" : each.value.healthCheck_TG.port
    protocol            =  each.value.healthCheck.protocol
    timeout             =  each.value.healthCheck.timeout
    healthy_threshold   =  each.value.healthCheck.healthy_threshold
    unhealthy_threshold =  each.value.healthCheck.unhealthy_threshold
    matcher             =  each.value.healthCheck.matcher
  }

  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}_${each.key}_TG" : "${each.key}_TG" }
  )

  depends_on = [ aws_lb.alb ]
}