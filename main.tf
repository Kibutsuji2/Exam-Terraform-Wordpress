terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Identifiants AWS lus depuis l'environnement (aws configure, variables AWS_*, rôle IAM) : jamais dans le code.
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.namespace
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  # Nom de périphérique partagé par les modules ec2 (montage) et ebs (attachement)
  data_device = "/dev/sdf"
}

module "networking" {
  source = "./modules/networking"

  namespace         = var.namespace
  vpc_cidr          = var.vpc_cidr
  enable_https      = var.enable_https
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

module "rds" {
  source = "./modules/rds"

  namespace               = var.namespace
  instance_class          = var.db_instance_class
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  subnet_ids              = module.networking.private_subnet_ids
  security_group_id       = module.networking.db_sg_id
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
}

module "ec2" {
  source = "./modules/ec2"

  namespace          = var.namespace
  instance_type      = var.instance_type
  subnet_id          = module.networking.public_subnet_ids[0]
  security_group_id  = module.networking.web_sg_id
  key_name           = var.key_name
  user_data_template = "${path.module}/install_wordpress.sh"
  db_host            = module.rds.address
  db_name            = var.db_name
  db_user            = var.db_username
  db_password        = var.db_password
  enable_https       = var.enable_https
  data_device        = local.data_device
}

module "ebs" {
  source = "./modules/ebs"

  namespace         = var.namespace
  availability_zone = module.ec2.availability_zone
  size              = var.ebs_size
  instance_id       = module.ec2.instance_id
  device_name       = local.data_device
}

output "wordpress_url" {
  description = "URL HTTP du site WordPress"
  value       = "http://${module.ec2.public_ip}"
}

output "wordpress_https_url" {
  description = "URL HTTPS du site (certificat autosigne)"
  value       = var.enable_https ? "https://${module.ec2.public_ip}" : null
}

output "ec2_public_ip" {
  description = "IP publique du serveur web"
  value       = module.ec2.public_ip
}

output "ec2_availability_zone" {
  description = "AZ du serveur web (identique a celle du volume EBS)"
  value       = module.ec2.availability_zone
}

output "ebs_volume_id" {
  description = "ID du volume EBS de persistance"
  value       = module.ebs.volume_id
}

output "ebs_availability_zone" {
  description = "AZ du volume EBS"
  value       = module.ebs.availability_zone
}

output "ami_id" {
  description = "AMI Amazon Linux 2023 selectionnee automatiquement"
  value       = module.ec2.ami_id
}

output "rds_endpoint" {
  description = "Endpoint de la base de donnees"
  value       = module.rds.endpoint
}

output "rds_multi_az" {
  description = "Base deployee sur 2 AZ (instance principale + standby)"
  value       = module.rds.multi_az
}

output "availability_zones" {
  description = "AZ utilisees par le reseau"
  value       = module.networking.availability_zones
}
