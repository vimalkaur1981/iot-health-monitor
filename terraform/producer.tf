resource "aws_ecs_task_definition" "producer" {
  family                   = "iot-health-monitor-producer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.g5_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "producer"
      image = "${aws_ecr_repository.producer.repository_url}:latest"
      essential = true
      environment = [
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = "${aws_instance.kafka.private_ip}:9092"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "producer" {
  name            = "producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public.id]
    assign_public_ip = true
  }
}