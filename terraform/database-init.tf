
resource "terraform_data" "database_init" {

  triggers_replace = [
    filesha256("${path.module}/schema.sql"),
    var.db_host,
    var.db_name
  ]

  connection {
    type        = "ssh"
    host        = var.ec2_public_ip
    user        = var.ec2_ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "2m"
  }

  provisioner "file" {
    source      = "${path.module}/schema.sql"
    destination = "/tmp/gobus-schema.sql"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y mysql-client cron",
      "sudo mkdir -p /opt/gobus",
      "sudo mv /tmp/gobus-schema.sql /opt/gobus/schema.sql",
      "sudo chmod 644 /opt/gobus/schema.sql",

      "sudo bash -c 'cat > /root/.my.cnf <<EOF\n[client]\nhost=${var.db_host}\nuser=${var.db_username}\npassword=${var.db_password}\ndatabase=${var.db_name}\nport=3306\nEOF'",
      "sudo chmod 600 /root/.my.cnf",

      "sudo mysql --defaults-extra-file=/root/.my.cnf < /opt/gobus/schema.sql",

      "sudo bash -c 'cat > /etc/cron.d/gobus-daily-trips <<EOF\n5 0 * * * root /usr/bin/mysql --defaults-extra-file=/root/.my.cnf < /opt/gobus/schema.sql >> /var/log/gobus-seed.log 2>&1\nEOF'",

      "sudo chmod 644 /etc/cron.d/gobus-daily-trips",
      "sudo systemctl enable --now cron"
    ]
  }
}
