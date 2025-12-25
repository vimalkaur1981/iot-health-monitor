data "aws_secretsmanager_secret" "gmail_password" {
  name = "gmail_password"
}

data "aws_secretsmanager_secret_version" "gmail_password" {
  secret_id = data.aws_secretsmanager_secret.gmail_password.id
}