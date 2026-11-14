
output "frontend_public_ip" {
  description = "GoBus Frontend Public IP"
  value       = aws_instance.frontend.public_ip
}

output "application_url" {
  description = "GoBus Application URL"
  value       = "http://${aws_instance.frontend.public_ip}"
}

output "backend_private_ip" {
  description = "GoBus Backend Private IP"
  value       = aws_instance.backend.private_ip
}

output "rds_endpoint" {
  description = "GoBus MySQL RDS Endpoint"
  value       = aws_db_instance.mysql.address
}

output "database_name" {
  value = aws_db_instance.mysql.db_name
}
