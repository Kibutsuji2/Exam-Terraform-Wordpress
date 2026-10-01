variable "namespace" {
  description = "Prefixe de nommage"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet public de l'instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group du serveur web"
  type        = string
}

variable "key_name" {
  description = "Paire de cles SSH (optionnel)"
  type        = string
  default     = null
}

variable "user_data_template" {
  description = "Chemin du script d'installation (template)"
  type        = string
}

variable "db_host" {
  description = "Nom d'hote de la base"
  type        = string
}

variable "db_name" {
  description = "Nom de la base"
  type        = string
}

variable "db_user" {
  description = "Utilisateur de la base"
  type        = string
}

variable "db_password" {
  description = "Mot de passe de la base"
  type        = string
  sensitive   = true
}

variable "enable_https" {
  description = "Active HTTPS sur le serveur"
  type        = bool
}

variable "data_device" {
  description = "Nom du peripherique du volume EBS de donnees"
  type        = string
}
