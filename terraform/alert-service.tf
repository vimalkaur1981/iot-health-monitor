#####################################################
# Secrets Manager - shared for UAT and PROD
#####################################################
resource "aws_secretsmanager_secret" "gmail_user" {
  name = "gmail_user-${terraform.workspace}"
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "gmail_user-${terraform.workspace}"
    Env  = terraform.workspace
  }
}

resource "aws_secretsmanager_secret_version" "gmail_user_version" {
  secret_id     = aws_secretsmanager_secret.gmail_user.id
  secret_string = var.GMAIL_USER
}

resource "aws_secretsmanager_secret" "gmail_password" {
  name = "gmail_password-${terraform.workspace}"  # make it workspace-aware
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "gmail_password-${terraform.workspace}"
    Env  = terraform.workspace
  }
}

resource "aws_secretsmanager_secret_version" "gmail_password_version" {
  secret_id     = aws_secretsmanager_secret.gmail_password.id
  secret_string = var.GMAIL_APP_PASSWORD
}

#####################################################
# ECS Task Definition
#####################################################
resource "aws_ecs_task_definition" "alert" {
  family                   = "iot-health-monitor-alert"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.group5_ecs_task_execution.arn
  task_role_arn = aws_iam_role.group5_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "alert"
      image     = "${aws_ecr_repository.alert_service.repository_url}:latest"
      essential = true

      # Non-sensitive environment variable
      environment = [
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = "${aws_instance.kafka.private_ip}:9092"
        },
        {
          name  = "ALERT_RECIPIENT"
          value = var.ALERT_RECIPIENT
        }
      ]

      # Sensitive variables stored in Secrets Manager
      secrets = [
        { name = "GMAIL_USER", valueFrom = aws_secretsmanager_secret_version.gmail_user_version.arn },
        { name = "GMAIL_APP_PASSWORD", valueFrom = aws_secretsmanager_secret_version.gmail_password_version.arn }
      ]

      # CloudWatch Logs configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${terraform.workspace}-iot-alert"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  tags = {
    Name = "${terraform.workspace}-iot-alert-task"
    Env  = terraform.workspace
  }
}

#####################################################
# CloudWatch Log Group
#####################################################
resource "aws_cloudwatch_log_group" "iot-alert" {
  name              = "/ecs/${terraform.workspace}-iot-alert"
  retention_in_days = 7

  tags = {
    Name = "${terraform.workspace}-log-group"
    Env  = terraform.workspace
  }
}

#####################################################
# ECS Service
#####################################################
resource "aws_ecs_service" "alert" {
  name            = "iot-alert"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alert.arn
  desired_count   = terraform.workspace == "prod" ? 3 : 1
  launch_type     = "FARGATE"

 network_configuration {
    subnets          = [for s in aws_subnet.public : s.id]
    assign_public_ip = true
  } 
  tags = {
    Name = "${terraform.workspace}-alert-service"
    Env  = terraform.workspace
  }
}