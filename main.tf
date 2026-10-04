resource "aws_instance" "bastion" {
    ami = "ami-ubuntu2404-amd64"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.xhtml
                nohup python3 -m http.server 8080 > /dev/null 2>&1 &
                EOF
    
    user_data_replace_on_change = true
    tags = {
        Name = "Linux Bastion"
    }
}

resource "aws_security_group" "instance" {
    name = "Terraform-stuff-instance"

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}