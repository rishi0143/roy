
# ==================================
# UBUNTU AMI
# ==================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


# ==================================
# BACKEND EC2 - FLASK
# ==================================

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh", {
    github_repo    = var.github_repo
    db_host        = aws_db_instance.mysql.address
    db_user        = var.db_user
    db_password    = var.db_password
    db_name        = var.db_name
    admin_username = var.admin_username
    admin_password = var.admin_password
    app_secret_key = var.app_secret_key
  })

  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-backend"
  }

  depends_on = [
    aws_db_instance.mysql
  ]
}


# ==================================
# FRONTEND EC2 - NGINX
# ==================================

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/frontend_user_data.sh", {
    backend_private_ip = aws_instance.backend.private_ip
  })

  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-frontend"
  }

  depends_on = [
    aws_instance.backend
  ]
}
