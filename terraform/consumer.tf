#####################################################
# ECS Task Definition
#####################################################
resource "aws_ecs_task_definition" "consumer" {
  family                   = "iot-health-monitor-consumer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.group5_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "consumer"
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
          awslogs-group         = "/ecs/${terraform.workspace}-iot-consumer"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  tags = {
    Name = "${terraform.workspace}-iot-consumer-task"
    Env  = terraform.workspace
  }
}

#####################################################
# CloudWatch Log Group
#####################################################
resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/ecs/${terraform.workspace}-iot-consumer"
  retention_in_days = 7

  tags = {
    Name = "${terraform.workspace}-log-group"
    Env  = terraform.workspace
  }
}

#####################################################
# ECS Service
#####################################################
resource "aws_ecs_service" "consumer" {
  name            = "iot-consumer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.consumer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.private : s.id]
    security_groups  = [aws_security_group.ecs.id]  # Attach ECS SG
    assign_public_ip = false
  }
  tags = {
    Name = "${terraform.workspace}-consumer-ecs-service"
    Env  = terraform.workspace
  }
}


