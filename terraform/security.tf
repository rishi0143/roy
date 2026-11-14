
# ==================================
# FRONTEND SECURITY GROUP
# ==================================

resource "aws_security_group" "frontend_sg" {
  name        = "${var.project_name}-frontend-sg"
  description = "GoBus Frontend Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP access from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-sg"
  }
}


# ==================================
# BACKEND SECURITY GROUP
# ==================================

resource "aws_security_group" "backend_sg" {
  name        = "${var.project_name}-backend-sg"
  description = "GoBus Backend Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Frontend to Backend API"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}


# ==================================
# DATABASE SECURITY GROUP
# ==================================

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "GoBus MySQL Database Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Backend to MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}
