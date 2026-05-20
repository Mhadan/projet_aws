provider "aws" {
  region = "us-east-1"
}

# =====================
# DEFAULT VPC
# =====================
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# =====================
# SECURITY GROUP
# =====================
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = data.aws_vpc.default.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# =====================
# EC2 INSTANCES
# =====================
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type = "t2.micro"

  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "ecommerce-server"
  }
}

# =====================
# OUTPUT
# =====================
output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}