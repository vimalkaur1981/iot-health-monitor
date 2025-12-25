resource "aws_ecs_cluster" "main" {
  name = "iot-health-monitor-${var.environment}"
  tags = {
    Environment = var.environment
    Project     = "iot-health-monitor"
  }
}
