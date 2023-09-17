variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "allocated_storage" { type = number }
variable "engine" { type = string }
variable "engine_version" {  type = string }
variable "instance_class" {  type = string }
variable "skip_final_snapshot" { default = false }
variable "vpc_security_group_ids" {}
variable "parameter_group_name" {}

# Create RDS 
resource "aws_db_instance" "rds_instance" {
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  skip_final_snapshot  = var.skip_final_snapshot
  parameter_group_name = var.parameter_group_name
  #vpc_security_group_ids = var.vpc_security_group_ids
  # Additional configuration parameters can be set here

  
}

