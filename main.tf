terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  access_key = var.accessID
  secret_key = var.secretkey
  region = "ap-south-1"
}
#Creating security groups and allow ssh, http and custom icmp
resource "aws_security_group" "terraform_sg" {
  name = "terraform_sg"
  description = "allow ssh, http and cutom icmp traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
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

# Create a VPC
resource "aws_key_pair" "amazon_linux" {
  key_name   = "amazon_linux"
  public_key = file(var.jenkins)
}
output "AWS_Link" {
  //value = concat([aws_instance.ubuntu.public_dns,""],[":8080/springboot-hellowolrd-0.0.1-SNAPSHOT",""])
  value=format("Access the AWS hosted app from here: %s%s", aws_instance.amazon_linux.public_dns, ":8080/springboot-hellowolrd-0.0.1-SNAPSHOT")
}

/*vpc_security_group_ids = [
    aws_security_group.amazon_linux.id
  ]*/



# Creating an ec2-instance

resource "aws_instance" "amazon_linux" {
  ami           = "ami-08e0ca9924195beba"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  security_groups = ["${aws_security_group.terraform_sg.name}"]
  key_name = aws_key_pair.amazon_linux.key_name
  tags = {
    Name = "Tomcat-server"
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.jenkins_pem)
    host        = self.public_ip
  }
  user_data = <<-EOF
  			#!bin/bash
  				sudo amazon-linux-extras install tomcat8.5
  				sudo systemctl enable tomcat
  				sudo systemctl start tomcat
  				cd /usr/share/tomcat/webapps/
  				sudo cp /tmp/springboot-hellowolrd-0.0.1-SNAPSHOT.war /usr/share/tomcat/webapps/springboot-hellowolrd-0.0.1-SNAPSHOT.war
			EOF
  provisioner "file" {
    source      = "/var/lib/jenkins/workspace/automate_java_app/target/springboot-hellowolrd-0.0.1-SNAPSHOT.war"
    destination = "/tmp/springboot-hellowolrd-0.0.1-SNAPSHOT.war"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.jenkins_pem)
      host        = self.public_ip
    }
  }
}

variable "jenkins" {
  type = string
  description = "this is my public key"
}
variable "jenkins_pem" {
  type = string
}
variable "accessID" {
  type = string
}
variable "secretkey" {
  type = string
}
