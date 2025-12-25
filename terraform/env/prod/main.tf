provider "aws" {
  region = "us-east-1"
}

module "iot_stack" {
  source      = "../../modules"
  environment = var.environment
}