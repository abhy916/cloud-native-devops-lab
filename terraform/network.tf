data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "app_sg" {
  name        = "cloud-native-devops-app-sg"
  description = "Allow HTTP access to Spring Boot application"
  vpc_id      = data.aws_vpc.default.id

ingress {
  description     = "Spring Boot application from ALB"
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  security_groups = [aws_security_group.alb_sg.id]
}
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud-native-devops-app-sg"
  }
}
