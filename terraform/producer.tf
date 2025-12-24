#####################################################
# ECS Task Definition
#####################################################
resource "aws_ecs_task_definition" "producer" {
  family                   = "iot-producer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.group5_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = "${aws_ecr_repository.producer.repository_url}:${var.producer_image_tag}"
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
          awslogs-group         = "/ecs/${terraform.workspace}-iot-producer"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${terraform.workspace}-iot-producer-task"
    Env  = terraform.workspace
  }
}

#####################################################
# CloudWatch Log Group
#####################################################
resource "aws_cloudwatch_log_group" "producer" {
  name              = "/ecs/${terraform.workspace}-iot-producer"
  retention_in_days = 7

  tags = {
    Name = "${terraform.workspace}-log-group"
    Env  = terraform.workspace
  }
}

#####################################################
# Security Groups
#####################################################
resource "aws_security_group" "alb" {
  name   = "${terraform.workspace}-producer-alb-sg"
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

  tags = {
    Name = "${terraform.workspace}-alb-sg"
    Env  = terraform.workspace
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name   = "${terraform.workspace}-producer-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id] 
  }
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-ecs-sg"
    Env  = terraform.workspace
  }
}

#####################################################
# Application Load Balancer
#####################################################
resource "aws_lb" "producer" {
  name               = "${terraform.workspace}-producer-tg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [for s in aws_subnet.public : s.id]
}

resource "aws_lb_target_group" "producer" {
  name        = "${terraform.workspace}-producer-tg"
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
  tags = {
    Name = "${terraform.workspace}-tg"
    Env  = terraform.workspace
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.producer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.producer.arn
  }
}

#####################################################
# ECS Service
#####################################################
resource "aws_ecs_service" "producer" {
  name            = "iot-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.private : s.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer.arn
    container_name   = "producer"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${terraform.workspace}-producer-ecs-service"
    Env  = terraform.workspace
  }
}

data "aws_route53_zone" "main" {
  name         = "sctp-sandbox.com"
  private_zone = false
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = terraform.workspace == "prod" ? "api.sctp-sandbox.com" : "uat-api.sctp-sandbox.com"
  type    = "A"

  alias {
    name                   = aws_lb.producer.dns_name
    zone_id                = aws_lb.producer.zone_id
    evaluate_target_health = true
  }
  # Tags are supported in Route53 for AWS provider >= 4.54
 }


