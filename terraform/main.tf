provider "aws" {
  region = "us-east-1"
}

# =====================
# VPC
# =====================
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# =====================
# Subnet public
# =====================
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

# =====================
# Security Group
# =====================
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================
# EC2 Instances
# =====================
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  subnet_id                  = aws_subnet.public.id
  vpc_security_group_ids     = [aws_security_group.web_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "ecommerce-server"
  }
}
output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}