provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2-instance" {
  ami = "ami-05576a079321f21f8"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2-http-ingress-rule.id, aws_security_group.ec2-ingress-rule.id, aws_security_group.ec2-http-egress-rule.id, aws_security_group.ec2-https-egress-rule.id, aws_security_group.ec2-ssh-ingress-rule.id]
  user_data = <<-EOF
              #!/bin/bash

              # Install Apache HTTP Server
              sudo yum update -y
              sudo yum install httpd -y

              # Start Apache and enable it on boot
              sudo systemctl start httpd
              sudo systemctl enable httpd

              # Create a "Hello, World" page
              echo "Hello, World!!!" | sudo tee /var/www/html/index.html
              EOF
  user_data_replace_on_change = true
}

resource "aws_security_group" "ec2-ssh-ingress-rule" {
  ingress {
    to_port = var.ssh_allowlisted_ports
    from_port = var.ssh_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
}

resource "aws_security_group" "ec2-ingress-rule" {
  ingress {
    to_port = var.default_allowlisted_ports
    from_port = var.default_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
}

resource "aws_security_group" "ec2-http-ingress-rule" {
  ingress {
    to_port = var.http_allowlisted_ports
    from_port = var.http_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
}


resource "aws_security_group" "ec2-http-egress-rule" {
  egress {
    to_port = var.http_allowlisted_ports
    from_port = var.http_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2-https-egress-rule" {
  egress {
    to_port = var.https_allowlisted_ports
    from_port = var.https_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "ssh_allowlisted_ports" {
  description = "ssh ingress and egress allowlisted ports"
  default = 22
  type = number
}

variable "http_allowlisted_ports" {
  description = "http ingress and egress allowlisted ports"
  default = 80
  type = number
}

variable "https_allowlisted_ports" {
  description = "https ingress and egress allowlisted ports"
  default = 443
  type = number
}

variable "default_allowlisted_ports" {
  description = "https ingress and egress allowlisted ports"
  default = 8080
  type = number
}

output "ip_address" {
  value = aws_instance.ec2-instance.public_ip
  description = "Public IP Address of the EC2 Instance"
}