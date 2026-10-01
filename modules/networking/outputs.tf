output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.this.id
}

output "availability_zones" {
  description = "AZ utilisees"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "IDs des subnets publics (un par AZ)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des subnets prives (un par AZ)"
  value       = aws_subnet.private[*].id
}

output "web_sg_id" {
  description = "Security group du serveur web"
  value       = aws_security_group.web.id
}

output "db_sg_id" {
  description = "Security group de la base"
  value       = aws_security_group.db.id
}
