#Application Load Balancer (alb): Internet (frontend)
resource "aws_lb" "alb" {
  name               = local.name-prefix != null ? "${replace(local.name-prefix,"_","-")}-LB" : "LB"
  internal           = var.internal
  security_groups    = flatten([var.alb_sg,aws_security_group.key.id])
  subnets            = var.vpc.public_subnet
  tags               = merge(
    var.tags,
    { Name = local.name-prefix != null ? "${local.name-prefix}_LB" : "LB" }
    )
}