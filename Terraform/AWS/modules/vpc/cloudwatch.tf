##CloudWatch log group [30 days retention]
resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = local.name-prefix != "" ? "VPCFlowLogsTF-${local.name-prefix}" : "VPCFlowLogsTF"
  retention_in_days = 30

  tags = merge(
    var.tags,
    { Name = local.name-prefix != "" ? "${local.name-prefix}-VPC-Logs" : "VPC-Logs"}
  )

  lifecycle {
    create_before_destroy = true
  }
}