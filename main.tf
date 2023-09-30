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
  secret_key = "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"
}
####################  VPC Configuration
resource "aws_vpc" "main_vpc" {
  tags = {
    Name = "main-vpc"
  }
  cidr_block = local.main_vpc.cidr
  
}


# Create Subnets
data "aws_availability_zones" "az" {
  state = "available"
}

resource "aws_subnet" "prod_subnet" {
  count = length(local.prod_ec2s)

  cidr_block = "10.0.0.${count.index}/24" #cidrsubnet(local.main_vpc.cidr, local.v4_env_offset+count.index,0) 
  vpc_id     = aws_vpc.main_vpc.id
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "prod-${count.index + 1}"
    
  }
resource "aws_db_subnet_group" "custom_db_subnet_group" {
  name       = "my-custom-db-subnet-group"
  description = "Custom DB Subnet Group"
  subnet_id = aws_subnet.prod_subnet[*].id
}
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main Internet Gateway"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_prod_rt_a" {
  count = length(local.prod_ec2s)
  subnet_id      = aws_subnet.prod_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
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
    cidr_blocks = ["10.0.0.0/24"]
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
    from_port   = 8000
    to_port     = 8000
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
  subnets = aws_subnet.prod_subnet
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
  db_subnet_group_name = aws_db_subnet_group.custom_db_subnet_group.name

  skip_final_snapshot = true # Change based on your retention policy
}

