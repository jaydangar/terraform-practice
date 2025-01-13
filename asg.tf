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

resource "aws_lb" "load-balancer" {
  name = "auto-load-balancer"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port = var.http_allowlisted_ports
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = aws_lb_listener.http-listener.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_lb_target_group" "target-group" {
  name = "target-group"
  port = var.http_allowlisted_ports
  protocol = "HTTP"
  vpc_id = aws_default_vpc.default.id
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "autoscaling-group" {
  launch_template {
    id = aws_launch_template.launch-configuration.id
    version = "$Latest"
  }
  health_check_type = "ELB"
  target_group_arns = [aws_lb_target_group.target-group.arn]
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

resource "aws_security_group" "alb" {
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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

output "elb_id" {
  value = aws_lb.load-balancer.dns_name
}