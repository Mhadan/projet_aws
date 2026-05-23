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
 
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = data.aws_vpc.default.id
 
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
    Name = "alb-sg"
  }
}
 
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-02b2c1b57c5105166"
  instance_type = "t2.micro"
  key_name      = "vockey"
 
  subnet_id                   = data.aws_subnets.default.ids[count.index]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
 
  tags = {
    Name = "ecommerce-server-${count.index + 1}"
  }
}
 
resource "aws_lb" "main" {
  name               = "ecommerce-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
 
  tags = {
    Name = "ecommerce-alb"
  }
}
 
resource "aws_lb_target_group" "web" {
  name     = "ecommerce-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
 
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
  }
}
 
resource "aws_lb_target_group_attachment" "web" {
  count            = 2
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
 
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
 
output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}
 
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}