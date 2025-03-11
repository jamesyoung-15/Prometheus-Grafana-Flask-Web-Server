provider "aws" {
  region  = "us-east-1"
  profile = "Dev"
}

# ssh key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# save key
resource "local_file" "ssh_pub_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "id_rsa.pub"
}

# ec2 key pair
resource "aws_key_pair" "practice_ec2_key" {
  key_name   = "test_ssh_key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}


# sg for ssh and http
resource "aws_security_group" "practice_ec2_sg" {
  name_prefix = "practice_sg-"
  description = "Allow ssh and http"
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

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
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

# ec2 instance
resource "aws_instance" "practice_ec2" {
  ami             = "ami-08b5b3a93ed654d19"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.practice_ec2_key.key_name
  security_groups = [aws_security_group.practice_ec2_sg.name]
  tags = {
    Name = "practice_ec2"
  }
  # install docker
  user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo yum install git docker -y
            sudo service docker start
            sudo usermod -a -G docker ec2-user

            sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            
            cd /home/ec2-user/
            git clone https://github.com/jamesyoung-15/Prometheus-Grafana-Flask-Web-Server
            cd Prometheus-Grafana-Flask-Web-Server
            PUBLIC_IP=$(curl -s ipinfo.io/ip)

            echo -e "global:\n  scrape_interval: 15s\nscrape_configs:\n  - job_name: 'python-web-server'\n    static_configs:\n      - targets: ['$PUBLIC_IP:5000']" > prometheus.yml
            sudo docker-compose up -d
            EOF
}