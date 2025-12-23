############################################
# TLS Key Pair for EC2
############################################
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = "iot-kafka-key-${terraform.workspace}"  # workspace-aware
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = {
    Name = "iot-kafka-key-${terraform.workspace}"
    Env  = terraform.workspace
  }
}

############################################
# Security Group for Kafka EC2
############################################
resource "aws_security_group" "group5_kafka" {
   name   = "group5-${terraform.workspace}kafka"  # workspace-aware
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs.id]
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
    Name = "group5-${terraform.workspace}-kafka"
    Env  = terraform.workspace
  }
}

############################################
# Kafka EC2 Instance
############################################
resource "aws_instance" "kafka" {
  ami                    = "ami-068c0051b15cdb816"
  instance_type          = "t3.micro"
  subnet_id = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.group5_kafka.id]
  key_name               = aws_key_pair.ec2_keypair.key_name

  user_data = file("${path.module}/kafka-install.sh")

   tags = {
    Name = "${terraform.workspace}-kafka-broker"  # workspace-aware
    Env  = terraform.workspace
  }
}

