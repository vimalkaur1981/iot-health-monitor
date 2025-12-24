# ECS Task Definition
resource "aws_ecs_task_definition" "producer" {
  family                   = "iot-producer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.g5_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = "${aws_ecr_repository.producer.repository_url}:latest"
      essential = true

      portMappings = [
        { containerPort = 8000, protocol = "tcp" }
      ]

      environment = [
        { name = "KAFKA_BOOTSTRAP_SERVERS", value = "${aws_instance.kafka.private_ip}:9092" },
        { name = "KAFKA_TOPIC", value = "iot-data" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/iot-producer"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "producer" {
  name              = "/ecs/iot-producer"
  retention_in_days = 7
}

# Security Groups

resource "aws_security_group" "alb" {
  name   = "producer-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress { 
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress { 
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  
  egress  { 
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs" {
  name   = "producer-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "producer" {
  name               = "producer-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [for s in aws_subnet.public : s.id]
}

resource "aws_lb_target_group" "producer" {
  name        = "producer-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

   health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.producer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.producer.arn
  }
}

# ECS Service
resource "aws_ecs_service" "producer" {
  name            = "producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.public : s.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer.arn
    container_name   = "producer"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}


data "aws_route53_zone" "main" {
  name         = "sctp-sandbox.com"
  private_zone = false
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.sctp-sandbox.com"
  type    = "A"

  alias {
    name                   = aws_lb.producer.dns_name
    zone_id                = aws_lb.producer.zone_id
    evaluate_target_health = true
  }
}


