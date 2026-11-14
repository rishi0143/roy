
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "gobus"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_name" {
  type    = string
  default = "busbooking"
}

variable "db_user" {
  type    = string
  default = "busadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "my_ip" {
  description = "Your public IPv4 address with /32"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "github_repo" {
  description = "Git repository containing the application"
  type        = string
}

variable "admin_username" {
  description = "GoBus owner login username"
  type        = string
}

variable "admin_password" {
  description = "GoBus owner login password"
  type        = string
  sensitive   = true
}

variable "app_secret_key" {
  description = "Flask application secret key"
  type        = string
  sensitive   = true
}
