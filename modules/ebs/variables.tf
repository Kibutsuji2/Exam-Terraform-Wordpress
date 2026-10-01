variable "namespace" {
  description = "Prefixe de nommage"
  type        = string
}

variable "availability_zone" {
  description = "AZ du volume : celle de l'instance EC2"
  type        = string
}

variable "size" {
  description = "Taille du volume (Go)"
  type        = number
}

variable "volume_type" {
  description = "Type de volume"
  type        = string
  default     = "gp3"
}

variable "instance_id" {
  description = "Instance a laquelle attacher le volume"
  type        = string
}

variable "device_name" {
  description = "Nom de peripherique de l'attachement"
  type        = string
}
