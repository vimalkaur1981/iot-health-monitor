resource "aws_ecr_repository" "producer" {
  name = "${terraform.workspace}-health-monitor-producer"

  tags = {
    Name = "${terraform.workspace}-health-monitor-producer"
    Env  = terraform.workspace
  }
}

resource "aws_ecr_repository" "consumer" {
  name = "${terraform.workspace}-health-monitor-consumer"

  tags = {
    Name = "${terraform.workspace}-health-monitor-consumer"
    Env  = terraform.workspace
  }
}

resource "aws_ecr_repository" "alert_service" {
  name = "${terraform.workspace}-health-monitor-alert-service"
  tags = {
    Name = "${terraform.workspace}-health-monitor-alert-service"
    Env  = terraform.workspace
  }
}