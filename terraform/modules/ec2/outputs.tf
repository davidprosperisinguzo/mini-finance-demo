output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.web.public_ip
}

output "private_ip" {
  description = "Private IP of EC2 instance"
  value       = aws_instance.web.private_ip
}
