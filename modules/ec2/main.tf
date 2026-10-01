# Derniere AMI Amazon Linux 2023 publiee par AWS, recuperee automatiquement
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  user_data = templatefile(var.user_data_template, {
    db_host         = var.db_host
    db_name         = var.db_name
    db_user         = var.db_user
    db_password_b64 = base64encode(var.db_password)
    enable_https    = var.enable_https ? "true" : "false"
    data_device     = var.data_device
  })
  user_data_replace_on_change = true

  # IMDSv2 obligatoire
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.namespace}-web"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
