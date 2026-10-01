resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  size              = var.size
  type              = var.volume_type
  encrypted         = true

  tags = {
    Name = "${var.namespace}-data"
  }
}

resource "aws_volume_attachment" "this" {
  device_name = var.device_name
  volume_id   = aws_ebs_volume.this.id
  instance_id = var.instance_id

  # Arrete proprement l'instance avant un detachement (destroy)
  stop_instance_before_detaching = true
}
