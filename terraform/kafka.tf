resource "aws_security_group" "g5-kafka" {
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
    cidr_blocks = ["122.11.214.195/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kafka" {
  ami                    = "ami-068c0051b15cdb816"
  instance_type          = "t3.micro"
  subnet_id = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.g5-kafka.id]
  key_name               = "group5-key-pair"

  user_data = file("${path.module}/kafka-install.sh")

  tags = {
    Name = "kafka-broker"
  }
}

