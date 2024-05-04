resource "aws_secretsmanager_secret" "hubmobeats" {
  name = var.project-tags.project != null && var.project-tags.project != "" ? "hubmobeats-${var.project-tags.project}" : "hubmobeats"
}

resource "aws_secretsmanager_secret_version" "hubmobeats" {
  secret_id     = aws_secretsmanager_secret.hubmobeats.id
  secret_string = jsonencode(var.hubmobeats)
}