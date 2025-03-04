terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.89.0"
    }
  }
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key"{
  type = string
}

provider "aws" {
  region     = "eu-west-3"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "my_sg"{
    name        = "my_sg"
    description = "Allow HTTP and SSH inbound traffic"
     
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
}

resource "aws_instance" "my_instance" {
  ami           = "ami-06e02ae7bdac6b938"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key.key_name
    security_groups = [aws_security_group.my_sg.name]

  tags = {
    Name = "react-website"
  }
}

resource "local_file" "ansible_hosts" {
  filename = "out/ansible_hosts"
  content = templatefile("templates/ansible_hosts.tftpl", {
    reactserverip = aws_instance.my_instance.public_ip,
    ssh_user      = "ubuntu",
    ssh_key_file  = "~/.ssh/id_rsa"
  })
}

output "public_ip" {
  value = aws_instance.my_instance.public_ip
}