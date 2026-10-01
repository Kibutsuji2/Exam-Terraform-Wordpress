output "address" {
  description = "Nom d'hote de la base (sans port)"
  value       = aws_db_instance.this.address
}

output "endpoint" {
  description = "Endpoint hote:port"
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "Port MySQL"
  value       = aws_db_instance.this.port
}

output "availability_zone" {
  description = "AZ de l'instance principale"
  value       = aws_db_instance.this.availability_zone
}

output "multi_az" {
  description = "Base deployee sur 2 AZ"
  value       = aws_db_instance.this.multi_az
}
