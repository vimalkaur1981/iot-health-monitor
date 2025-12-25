resource "aws_ecr_repository" "producer" {
  name = "iot-health-monitor-producer-${var.environment}"
  force_delete = true
  tags = {
    Environment = var.environment
    Project     = "iot-health-monitor"
  }
}

resource "aws_ecr_repository" "consumer" {
  name = "iot-health-monitor-consumer-${var.environment}"
  force_delete = true
  tags = {
    Environment = var.environment
    Project     = "iot-health-monitor"
  }
}

resource "aws_ecr_repository" "alert_service" {
  name = "iot-health-monitor-alert-service-${var.environment}"
  force_delete = true
  tags = {
    Environment = var.environment
    Project     = "iot-health-monitor"
  }
}