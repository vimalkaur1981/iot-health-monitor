resource "aws_ecs_task_definition" "consumer" {
  family                   = "iot-health-monitor-consumer-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.g5_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "consumer-${var.environment}"
      image     = "${aws_ecr_repository.consumer.repository_url}:latest"  # Use consumer repo
      essential = true

      portMappings = [
        { containerPort = 8002, protocol = "tcp" }  # Prometheus metrics
      ]

      environment = [
        { name = "KAFKA_BOOTSTRAP_SERVERS", value = "${aws_instance.kafka.private_ip}:9092" },
        { name = "STATUS_TOPIC", value = "iot-data" },
        { name = "ALERT_TOPIC", value = "device-alerts" },
        { name = "DEVICE_TIMEOUT", value = "120" },
        { name = "CHECK_INTERVAL", value = "5" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/iot-consumer"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  tags = {
    Environment = var.environment
    Project     = "iot-health-monitor"
  }
}


resource "aws_ecs_service" "consumer" {
  name            = "consumer-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.consumer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.public : s.id]
    security_groups  = [aws_security_group.ecs.id]  # Attach ECS SG
    assign_public_ip = true
  }
}

resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/ecs/iot-consumer-${var.environment}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = "iot-health-monitor"
  }
}
