resource "random_password" "app_secret_key" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "app_db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.project}/${var.environment}/app/secrets"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    secret_key = random_password.app_secret_key.result
    db_password    = random_password.app_db_password.result
  })
}
