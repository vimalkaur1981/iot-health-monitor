resource "aws_ecr_repository" "producer" {
  name = "producer"
}

resource "aws_ecr_repository" "consumer" {
  name = "consumer"
}

resource "aws_ecr_repository" "alert-service" {
  name = "alerting"
}
