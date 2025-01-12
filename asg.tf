provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_template" "launch-configuration" {
  image_id = "ami-05576a079321f21f8"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2-http-ingress-rule.id, aws_security_group.ec2-ingress-rule.id, aws_security_group.ec2-http-egress-rule.id, aws_security_group.ec2-https-egress-rule.id, aws_security_group.ec2-ssh-ingress-rule.id]
  user_data = filebase64("${path.cwd}/bash.sh")
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling-group" {
  launch_template {
    id = aws_launch_template.launch-configuration.id
    version = "$Latest"
  } 
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size = 2
  max_size = 5
  desired_capacity = 2
}

resource "aws_security_group" "ec2-ssh-ingress-rule" {
  name = "ec2-ssh-ingress-rule"
  ingress {
    to_port = var.ssh_allowlisted_ports
    from_port = var.ssh_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
}

resource "aws_security_group" "ec2-ingress-rule" {
  name = "ec2-ingress-rule"
  ingress {
    to_port = var.default_allowlisted_ports
    from_port = var.default_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
}

resource "aws_security_group" "ec2-http-ingress-rule" {
  name = "ec2-http-ingress-rule"
  ingress {
    to_port = var.http_allowlisted_ports
    from_port = var.http_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
}

resource "aws_security_group" "ec2-http-egress-rule" {
  name = "ec2-http-egress-rule"
  egress {
    to_port = var.http_allowlisted_ports
    from_port = var.http_allowlisted_ports
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2-https-egress-rule" {
  name = "ec2-https-egress-rule"
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

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

output "default_subnet_ids" {
  value = data.aws_subnets.default.ids
}
