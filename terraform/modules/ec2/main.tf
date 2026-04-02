data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ssh_public_key = try(trimspace(file(pathexpand(var.ssh_public_key_path))), "")
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  associate_public_ip_address = true

  user_data = local.ssh_public_key != "" ? base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    ssh_public_key = local.ssh_public_key
  })) : null

  tags = {
    Name = "${var.environment}-instance"
  }
}
