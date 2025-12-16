resource "aws_ecs_task_definition" "alert_service" {
  family                   = "iot-health-monitor-alert-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.g5_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "alert-service"
      image     = "${aws_ecr_repository.alert_service.repository_url}:${var.alert_service_image_tag}"
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

resource "aws_ecs_service" "alert_service" {
  name            = "alert-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alert_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    assign_public_ip = true
  }
}

