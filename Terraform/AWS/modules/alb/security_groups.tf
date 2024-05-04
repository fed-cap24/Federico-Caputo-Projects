resource "aws_security_group" "lock"{
    for_each = var.lock_security_groups

    vpc_id      = var.vpc.id

    name        = local.name-prefix != null ? "${local.name-prefix}_${each.key}_LOCK_SG" : "${each.key}_LOCK_SG" 
    description = each.value.description

    dynamic "ingress" {
        for_each = each.value.ingress
        content{
            from_port       = ingress.value.from_port
            to_port         = ingress.value.to_port
            protocol        = ingress.value.protocol
            security_groups = [aws_security_group.key.id]
            description     = ingress.value.description
        }   
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        security_groups = [aws_security_group.key.id]
        description     = "Only Allow Egress traffic to the load balancer"
    }

    tags = merge(
    var.tags,
    { Name = local.name-prefix != null ? "${local.name-prefix}_${each.key}_LOCK_SG" : "${each.key}_LOCK_SG" }
    )
}

resource "aws_security_group" "key" {
    vpc_id          =   var.vpc.id
    name            =   local.name-prefix != null ? "${local.name-prefix}_LB_KEY_SG" : "LB_KEY_SG"
    description     =   "Security Group for load balancer, it acts as a Key for all *_LOCK_SG elements (with matching prefix)"

    tags = merge(
    var.tags,
    { Name = local.name-prefix != null ? "${local.name-prefix}_LB_KEY_SG" : "LB_KEY_SG" }
    )
}