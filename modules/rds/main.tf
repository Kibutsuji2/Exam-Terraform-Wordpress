resource "aws_db_subnet_group" "this" {
  name        = "${var.namespace}-db-subnets"
  description = "Subnets prives de la base (2 AZ)"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.namespace}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.namespace}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  # Instance principale + standby synchrone dans une 2e AZ
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  backup_retention_period    = var.backup_retention_period
  auto_minor_version_upgrade = true
  apply_immediately          = true

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.namespace}-db"
  }
}
