variable "region" {
  description = "Region AWS"
  type        = string
  default     = "eu-west-3"
}

variable "namespace" {
  description = "Prefixe de nommage de toutes les ressources (sert aussi d'identifiant RDS)"
  type        = string
  default     = "wordpress"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,40}[a-z0-9]$", var.namespace)) && !strcontains(var.namespace, "--")
    error_message = "namespace : minuscules, chiffres et tirets uniquement, commence par une lettre, 3 a 42 caracteres, sans '--' ni tiret final."
  }
}

variable "environment" {
  description = "Nom de l'environnement (tag)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Plage d'adresses du VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr doit etre un bloc CIDR valide, par exemple 10.0.0.0/16."
  }
}

variable "instance_type" {
  description = "Type de l'instance EC2 du serveur web"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nom d'une paire de cles EC2 existante pour SSH (optionnel)"
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "CIDR autorises en SSH (vide = SSH ferme), par exemple [\"203.0.113.10/32\"]"
  type        = list(string)
  default     = []
}

variable "enable_https" {
  description = "Active HTTPS (port 443, certificat autosigne) - bonus"
  type        = bool
  default     = true
}

variable "ebs_size" {
  description = "Taille du volume EBS de persistance (Go)"
  type        = number
  default     = 10

  validation {
    condition     = var.ebs_size >= 1 && var.ebs_size <= 16384
    error_message = "ebs_size doit etre compris entre 1 et 16384 Go."
  }
}

variable "db_instance_class" {
  description = "Classe de l'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine" {
  description = "Moteur de base de donnees compatible MySQL"
  type        = string
  default     = "mariadb"

  validation {
    condition     = contains(["mariadb", "mysql"], var.db_engine)
    error_message = "db_engine doit valoir mariadb ou mysql."
  }
}

variable "db_engine_version" {
  description = "Version du moteur (MariaDB 10.11 LTS par defaut)"
  type        = string
  default     = "10.11"
}

variable "db_allocated_storage" {
  description = "Stockage RDS (Go)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nom de la base WordPress"
  type        = string
  default     = "wordpress"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,63}$", var.db_name))
    error_message = "db_name : commence par une lettre, puis lettres, chiffres ou '_' (64 caracteres max)."
  }
}

variable "db_username" {
  description = "Utilisateur principal de la base"
  type        = string
  default     = "wpadmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,15}$", var.db_username)) && lower(var.db_username) != "rdsadmin"
    error_message = "db_username : commence par une lettre, lettres/chiffres/'_' uniquement, 16 caracteres max, 'rdsadmin' interdit."
  }
}

variable "db_password" {
  description = "Mot de passe de la base : a fournir via TF_VAR_db_password, jamais dans le code"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 41 && can(regex("^[!#-.0-?A-~]+$", var.db_password))
    error_message = "db_password : 8 a 41 caracteres ASCII imprimables, sans espace, '/', '@' ni '\"'."
  }
}

variable "db_multi_az" {
  description = "Deploie la base sur 2 AZ (instance principale + standby synchrone)"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Jours de retention des sauvegardes automatiques RDS (0 = desactive)"
  type        = number
  default     = 1
}
