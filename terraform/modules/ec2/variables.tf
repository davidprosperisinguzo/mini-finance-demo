variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for EC2 instance"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (optional - provide only if file exists)"
  type        = string
  default     = ""
}
