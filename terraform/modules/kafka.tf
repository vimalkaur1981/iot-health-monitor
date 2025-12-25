resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = "iot-kafka-key-${var.environment}"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_security_group" "g5-kafka" {
  name = "kafka-broker-${var.environment}"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = var.environment
    Project     = "iot-health-monitor"
  }
}

resource "aws_instance" "kafka" {
  ami                    = "ami-068c0051b15cdb816"
  instance_type          = "t3.micro"
  subnet_id = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.g5-kafka.id]
  key_name               = aws_key_pair.ec2_keypair.key_name

  user_data = file("${path.module}/kafka-install.sh")

  tags = {
    Environment = var.environment
    name     = "ec2-kafka-broker"
    Project     = "iot-health-monitor"
  }
}

