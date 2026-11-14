
# ==================================
# RDS SUBNET GROUP
# ==================================

resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnets"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

# ==================================
# MYSQL RDS DATABASE
# ==================================

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 30
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  port = 3306

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false
  multi_az            = false

  storage_encrypted       = true
  backup_retention_period = 1

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
