output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "public_ip" {
  description = "Public IPv4 address of the application server"
  value       = aws_instance.app_server.public_ip
}

output "application_url" {
  description = "Spring Boot health endpoint through the Application Load Balancer"
  value       = "http://${aws_lb.app_alb.dns_name}/health"
}
