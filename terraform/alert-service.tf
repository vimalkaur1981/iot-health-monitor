# ---------------------
# Create Secrets in AWS Secrets Manager
# ---------------------

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
  task_role_arn = aws_iam_role.g5_ecs_task_role.arn

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
          name  = "GMAIL_USER"
          value = var.gmail_user
        },
        {
          name  = "ALERT_RECIPIENT"
          value = var.alert_recipient
        }
      ]

      # Sensitive variables stored in Secrets Manager
      secrets = [
        { name = "GMAIL_APP_PASSWORD", valueFrom = data.aws_secretsmanager_secret.gmail_password.arn }
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

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "iot-alert" {
  name              = "/ecs/iot-alert"
  retention_in_days = 7
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
    subnets          = [for s in aws_subnet.public : s.id]
    assign_public_ip = true
  } 
}