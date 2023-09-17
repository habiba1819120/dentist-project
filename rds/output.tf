output "rds_instance"{
    value = aws_db_instance.rds_instance
}
output "database_username" {
  value = local.db_username
}