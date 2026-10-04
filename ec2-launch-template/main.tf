resource "aws_launch_configuration" "bastion_servers" {
  image_id        = "ami-ubuntu2404-amd64"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.xhtml
                nohup python3 -m http.server ${var.server_port} > /dev/null 2>&1 &
                EOF

  lifecycle {
    /* It solves a Terraform ordering problem, not a rollout problem. 
       The ASG references the launch template, so if a change forces Terraform to replace the template,
       the default destroy-then-create order would try to delete something the ASG is still using.
       With the setting, Terraform creates the new template, repoints the ASG, and then deletes the old one.
    */
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "webservers" {
  launch_configuration = aws_launch_configuration.bastion_servers.name
  vpc_zone_identifier  = data.aws_subnets.mysubnets.ids

  target_group_arns = [aws_lb_target_group.floci-alb-tg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "Terraform-floci-asg" # Will create EC2 instances tagged with the name 'Terraform-floci-asg'
    propagate_at_launch = true
  }

}

resource "aws_lb" "floci_alb" {
  name               = "terraform-floci-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.mysubnets.ids
  security_groups    = [aws_security_group.floci_alb_sg.id]
}

resource "aws_lb_listener" "floci_http_rules" {
  load_balancer_arn = aws_lb.floci_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "floci_asg" {
  listener_arn = aws_lb_listener.floci_http_rules.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.floci-alb-tg.arn
  }
}

resource "aws_security_group" "floci_alb_sg" {
  name = "terraform-floci-alb-rule"

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

resource "aws_lb_target_group" "floci-alb-tg" {
  name     = "terraform-floci-alb-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.myvpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

data "aws_vpc" "myvpc" {
  default = true
}

data "aws_subnets" "mysubnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.myvpc.id]
  }
}

resource "aws_security_group" "instance" {
  name = "Terraform-stuff-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

variable "server_port" {
  description = "Port of the server running on the EC2"
  type        = number
  default     = 8080

}

output "alb_dns_name" {
  value       = aws_lb.floci_alb.dns_name
  description = "Domain name of floci load balancer"
}
