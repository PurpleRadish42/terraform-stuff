resource "aws_instance" "bastion" {
  ami                    = "ami-ubuntu2404-amd64"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.xhtml
                nohup python3 -m http.server ${var.server_port} > /dev/null 2>&1 &
                EOF

  user_data_replace_on_change = true
  tags = {
    Name = "Linux Bastion"
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

output "public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP of the EC2 Instance"

}

variable "server_port" {
  description = "Port of the server running on the EC2"
  type        = number
  default     = 8080

}
