# ---------------------
# Create Secrets in AWS Secrets Manager
# ---------------------
resource "aws_secretsmanager_secret" "gmail_user" {
  name = "gmail_user"
}

resource "aws_secretsmanager_secret_version" "gmail_user_version" {
  secret_id     = aws_secretsmanager_secret.gmail_user.id
  secret_string = var.GMAIL_USER
}

resource "aws_secretsmanager_secret" "gmail_password" {
  name = "gmail_password"
}

resource "aws_secretsmanager_secret_version" "gmail_password_version" {
  secret_id     = aws_secretsmanager_secret.gmail_password.id
  secret_string = var.GMAIL_APP_PASSWORD
}

# ---------------------
# ECS Task Definition
# ---------------------
resource "aws_ecs_task_definition" "alert" {
  family                   = "iot-health-monitor-alert"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.g5_ecs_task_execution.arn

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
        { name = "GMAIL_USER", valueFrom = aws_secretsmanager_secret.gmail_user.arn },
        { name = "GMAIL_APP_PASSWORD", valueFrom = aws_secretsmanager_secret.gmail_password.arn }
      ]

      # CloudWatch Logs configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/iot-alert"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ---------------------
# ECS Service
# ---------------------
resource "aws_ecs_service" "alert" {
  name            = "alert"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alert.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    assign_public_ip = true
  }
}