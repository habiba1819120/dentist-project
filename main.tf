terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #       version = "4.61.0"
    }
  }
}



provider "aws" {
  region = "us-east-1" # Update with appropriate region
  access_key = "AKIAV2OBSZ2QIR4D5UHC"
  secret_key = "UbelDCIjt7CmbRfZgKGOt48RSuzzCT0l0ezlU7ck"
}
####################  VPC Configuration
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block
  tags = {
    Name = "CustomVPC"
  }
}

resource "aws_subnet" "rds_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24" # Replace with your desired RDS subnet CIDR block
  availability_zone = "us-east-1a" # Replace with your desired availability zone
  tags = {
    Name = "RDS_Subnet"
  }
}

resource "aws_db_subnet_group" "rds_db_subnet_group" {
  name        = "denstistSubnetGroup"
  description = "Custom DB Subnet Group"
  subnet_ids  = [aws_subnet.rds_subnet.id]
}

resource "aws_subnet" "ec2_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24" # Replace with your desired EC2 subnet CIDR block
  availability_zone = "us-east-1b" # Replace with your desired availability zone
  tags = {
    Name = "EC2_Subnet"
  }
}
###########Security Group ##############
##########################################"
###########Security Group ##############""

resource "aws_security_group" "rds_sg" {
  name_prefix        = "rds-sg-"
  vpc_id             = aws_vpc.main_vpc.id

  # Add rules to allow incoming traffic from your EC2 instance
  ingress {
    from_port   = 5432 # PostgreSQL default port
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.ec2_subnet.cidr_block]
  }
}

resource "aws_security_group" "ec2_sg" {
  name_prefix        = "ec2-sg-"
  vpc_id             = aws_vpc.main_vpc.id

  # Add rules to allow outgoing traffic to the public RDS instance
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
}
######################################################
##########" Resources ###############################
module "prod_ec2" {
  for_each = local.prod_ec2s
  source = "./ec2"
  name = each.key
  settings = each.value  
  subnets = aws_subnet.ec2_subnet
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

data "aws_eip" "aws_eip" {
  for_each =  local.prod_ec2s
  id = local.prod_aws_eips[each.key]
}
###########
#Associate EIP with EC2 Instance
resource "aws_eip_association" "aws_eip_association" {
  for_each =  module.prod_ec2
  instance_id = module.prod_ec2[each.key].ec2_instance[0].id
  allocation_id = data.aws_eip.aws_eip[each.key].id
}
############# RDS ######
module "rds" {
  source = "./rds"
  allocated_storage    = local.rds.prod-db-postgres.allocated_storage
  engine               = local.rds.prod-db-postgres.engine
  engine_version       = local.rds.prod-db-postgres.engine_version 
  instance_class       = local.rds.prod-db-postgres.instance_class 
  db_name              = local.rds.prod-db-postgres.db_name  
  db_username          = local.rds.prod-db-postgres.db_username 
  db_password          = local.rds.prod-db-postgres.db_password 
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  #subnet_group_name     = "default" # Replace with your subnet group name if needed


  skip_final_snapshot = true # Change based on your retention policy
}

