resource "aws_ecs_cluster" "main" {
  name = "${terraform.workspace}-iot-health-monitor"

  tags = {
    Name = "${terraform.workspace}-iot-health-monitor"
    Env  = terraform.workspace
  }
}
