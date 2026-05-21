terraform {
  backend "s3" {
    bucket = "terraform-state-projet-aws-1779358043"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
 
provider "aws" {
  region = "us-east-1"
}
 
data "aws_vpc" "default" {
  default = true
}
 
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
 
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = data.aws_vpc.default.id
 
  lifecycle {
    create_before_destroy = false
    ignore_changes        = [name]
  }
 
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
 
  tags = {
    Name = "web-sg"
  }
}
 
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-02b2c1b57c5105166"
  instance_type = "t2.micro"
  key_name      = "vockey"
 
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
 
  tags = {
    Name = "ecommerce-server"
  }
}
 
output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}
