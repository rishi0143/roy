
variable "aws_region" {
  default = "ap-south-1"
}

variable "project_name" {
  default = "gobus"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "db_name" {
  default = "busbooking"
}

variable "db_user" {
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
