resource "aws_instance" "bastion" {
    ami = "ami-ubuntu2404-amd64"
    instance_type = "t2.micro"

    tags = {
        Name = "Linux Bastion"
    }
}