module "networking" {
  source = "./modules/networking"

  aws_region             = var.aws_region
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidr     = var.public_subnet_cidr
  private_subnet_cidr    = var.private_subnet_cidr
}

module "security" {
  source = "./modules/security"

  vpc_id      = module.networking.vpc_id
  environment = var.environment
}

module "ec2" {
  source = "./modules/ec2"

  instance_type         = var.instance_type
  subnet_id             = module.networking.public_subnet_id
  security_group_id     = module.security.ec2_security_group_id
  environment           = var.environment
  ssh_public_key_path   = var.ssh_public_key_path
}
