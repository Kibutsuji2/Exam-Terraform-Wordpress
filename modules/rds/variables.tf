variable "namespace" {
  description = "Prefixe de nommage (identifiant RDS)"
  type        = string
}

variable "instance_class" {
  description = "Classe de l'instance"
  type        = string
}

variable "engine" {
  description = "Moteur (mariadb ou mysql)"
  type        = string
}

variable "engine_version" {
  description = "Version du moteur"
  type        = string
}

variable "allocated_storage" {
  description = "Stockage (Go)"
  type        = number
}

variable "db_name" {
  description = "Nom de la base initiale"
  type        = string
}

variable "db_username" {
  description = "Utilisateur principal"
  type        = string
}

variable "db_password" {
  description = "Mot de passe principal"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Subnets prives dans au moins 2 AZ"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group de la base"
  type        = string
}

variable "multi_az" {
  description = "Deploiement sur 2 AZ"
  type        = bool
}

variable "backup_retention_period" {
  description = "Retention des sauvegardes (jours)"
  type        = number
}
