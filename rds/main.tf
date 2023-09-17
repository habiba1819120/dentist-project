variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "allocated_storage" {}
variable "engine" {}
variable "engine_version" {}
variable "instance_class" {}
variable "skip_final_snapshot" { default = false }
variable "vpc_security_group_ids" {}
variable "subnets" {}

# Create RDS 
resource "aws_db_instance" "rds_instance" {
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  skip_final_snapshot  = var.skip_final_snapshot
  subnet_id     = var.subnets[count.index].id 
  #vpc_security_group_ids = var.vpc_security_group_ids
  # Additional configuration parameters can be set here

  tags = {
    Name = var.db_name
  }
}

