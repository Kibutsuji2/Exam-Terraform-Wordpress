output "volume_id" {
  description = "ID du volume EBS"
  value       = aws_ebs_volume.this.id
}

output "availability_zone" {
  description = "AZ du volume"
  value       = aws_ebs_volume.this.availability_zone
}

output "device_name" {
  description = "Nom de peripherique"
  value       = aws_volume_attachment.this.device_name
}
