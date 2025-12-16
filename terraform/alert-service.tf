resource "aws_ecs_task_definition" "alert-service" {
  family                   = "iot-health-monitor-alert-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.g5_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "alert-service"
      image = "${aws_ecr_repository.producer.repository_url}:latest"
      essential = true
      environment = [
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = "${aws_instance.kafka.private_ip}:9092"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/alert-service"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "alert-service" {
  name            = "alert-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alert-service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public.id]
    assign_public_ip = true
  }
}

