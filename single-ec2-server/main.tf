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
  name = "Terraform-stuff-instance-${terraform.workspace}"

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

terraform {
  backend "s3" {
    bucket                      = "terraform-up-and-running-state"
    key                         = "workspaces-example/terraform.tfstate"
    region                      = "ap-south-1"
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true
    use_lockfile                = true

    endpoints = {
      s3 = "http://localhost:4566"
    }
  }
}
