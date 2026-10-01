output "instance_id" {
  description = "ID de l'instance"
  value       = aws_instance.this.id
}

output "availability_zone" {
  description = "AZ de l'instance"
  value       = aws_instance.this.availability_zone
}

output "public_ip" {
  description = "IP publique"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "IP privee"
  value       = aws_instance.this.private_ip
}

output "ami_id" {
  description = "AMI utilisee"
  value       = aws_instance.this.ami
}
