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
####################VPC Configuration
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block
  tags = {
    Name = "mainVPC"
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


resource "aws_subnet" "ec2_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24" # Replace with your desired EC2 subnet CIDR block
  availability_zone = "us-east-1b" # Replace with your desired availability zone
  tags = {
    Name = "EC2_Subnet"
  }
}
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
###################EC2
resource "aws_instance" "ec2_instance" {
  ami           = "ami-04cb4ca688797756f" # Replace with your desired AMI ID
  instance_type = "t2.micro"              # Replace with your desired instance type
  subnet_id     = aws_subnet.ec2_subnet.id
  key_name      = "testonly"         # Replace with your EC2 key pair name

  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = "MyEC2Instance"
  }
}
############# RDS ######
resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  db_name                 = "mydb"
  db_username             = "dbusername"
  db_password             = "dbpassword"
  parameter_group_name = "default.postgres13"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  subnet_group_name     = "default" # Replace with your subnet group name if needed

  # Replace with your desired DB identifier and name
  identifier = "mydb"
  db_name    = "mydb"

  skip_final_snapshot = true # Change based on your retention policy
}

