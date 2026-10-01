variable "namespace" {
  description = "Prefixe de nommage"
  type        = string
}

variable "vpc_cidr" {
  description = "Plage d'adresses du VPC"
  type        = string
}

variable "az_count" {
  description = "Nombre d'AZ utilisees (2 minimum pour RDS)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "RDS exige au moins 2 AZ."
  }
}

variable "enable_https" {
  description = "Ouvre le port 443"
  type        = bool
}

variable "ssh_allowed_cidrs" {
  description = "CIDR autorises en SSH (vide = aucun)"
  type        = list(string)
}
