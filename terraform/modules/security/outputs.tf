output "ec2_security_group_id" {
  description = "Security group ID for EC2"
  value       = aws_security_group.ec2.id
}
