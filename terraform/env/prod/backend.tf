terraform {
  backend "s3" {
    bucket         = "g5-terraform-states"
    key            = "prod/iot-health.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
