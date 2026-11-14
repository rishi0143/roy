
output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "application_url" {
  value = "http://${aws_instance.app.public_ip}:5000"
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "database_name" {
  value = aws_db_instance.mysql.db_name
}
