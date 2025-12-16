resource "aws_ecs_task_definition" "consumer" {
  family                   = "iot-health-monitor-consumer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.iot_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "consumer"
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
          awslogs-group         = "/ecs/consumer"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "consumer" {
  name            = "consumer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.consumer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public.id]
    assign_public_ip = true
  }
}