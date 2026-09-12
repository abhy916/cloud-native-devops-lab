data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "cloud-native-devops-app"
  }
    user_data = <<-EOF
    #!/bin/bash
    set -e

    dnf install -y docker

    systemctl enable docker
    systemctl start docker

    aws ecr get-login-password --region us-east-1 | \
      docker login --username AWS --password-stdin \
      439126042992.dkr.ecr.us-east-1.amazonaws.com

    docker pull \
      439126042992.dkr.ecr.us-east-1.amazonaws.com/cloud-native-devops-app:7

    docker run -d \
      --name devops-app \
      --restart unless-stopped \
      -p 8080:8080 \
      439126042992.dkr.ecr.us-east-1.amazonaws.com/cloud-native-devops-app:7
  EOF
}
