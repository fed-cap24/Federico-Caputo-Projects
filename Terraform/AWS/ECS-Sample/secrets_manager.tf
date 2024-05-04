resource "aws_secretsmanager_secret" "secret" {
  name = var.project-tags.project != null && var.project-tags.project != "" ? "secret-${var.project-tags.project}" : "secret"
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode(var.secret)
}