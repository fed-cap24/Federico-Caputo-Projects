output "target_groups_arn" {
  description = "Map of target group arn"
  value = { for k,v in aws_lb_target_group.tg :
    k => v.arn
  }
}

output "lock_SGs" {
  description = "Lock security groups IDs"
  value = { for k, sg in aws_security_group.lock : k => sg.id }
}