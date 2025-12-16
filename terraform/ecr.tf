resource "aws_ecr_repository" "producer" {
  name = "g5-health-monitor-producer"
}

resource "aws_ecr_repository" "consumer" {
  name = "g5-health-monitor-consumer"
}

resource "aws_ecr_repository" "alert_service" {
  name = "g5-health-monitor-alert-service"
}