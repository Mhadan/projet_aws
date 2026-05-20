provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type = "t2.micro"

  tags = {
    Name = "ecommerce-server"
  }
}
output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}