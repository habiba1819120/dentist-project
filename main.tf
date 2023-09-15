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
  access_key = "AKIAV2OBSZ2QOARKG5NB"
  secret_key = "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"
}

###########
####    VPC  
###########

####### Create VPC
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

  cidr_block = "10.0.${count.index}.0/24" #cidrsubnet(local.main_vpc.cidr, local.v4_env_offset+count.index,0) 
  vpc_id     = aws_vpc.main_vpc.id
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "prod-${count.index + 1}"
  }
}



resource "aws_internet_gateway" "main_ig" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main Internet Gateway"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main_ig.id
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


##########################################
##########      PROD ENV
###########################################
## Security Group ###
resource "aws_security_group" "prod_web_sg" {
  name   = "prod_web_sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 8081
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 8082
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#### Modules ####
module "prod_ec2" {
  for_each = local.prod_ec2s
  source = "./ec2"
  name = each.key
  settings = each.value  
  subnets = aws_subnet.prod_subnet
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  vpc_security_group_ids = [aws_security_group.prod_web_sg.id]
}

data "aws_eip" "aws_eip" {
  for_each =  local.prod_ec2s
  id = local.prod_aws_eips[each.key]
}

#Associate EIP with EC2 Instance
resource "aws_eip_association" "aws_eip_association" {
  for_each =  module.prod_ec2
  instance_id = module.prod_ec2[each.key].ec2_instance[0].id
  allocation_id = data.aws_eip.aws_eip[each.key].id
}

#############
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main_vpc.id

  # Define inbound rules to allow access to the RDS instance.
  # Modify these rules as needed.
  ingress {
    from_port   = 5432  # PostgreSQL default port
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_eip.aws_eip[each.key].public_ip]
  }
}
module "elb" {
  source = "./rds"
  settings = local.rds
  target =  module.prod_ec2
  vpc =  aws_vpc.main_vpc
  security_groups = aws_security_group.prod_rds_sg
  subnets = aws_subnet.prod_subnet 
}

###########
####   Load Balancer 
###########

###### elb and  target group
module "elb" {
  source = "./elb"
  settings = local.elb
  target =  module.prod_ec2
  vpc =  aws_vpc.main_vpc
  security_groups = aws_security_group.prod_web_sg
  subnets = aws_subnet.prod_subnet 
}



###########
####   route53 
###########

##### route53 record

#data "aws_route53_zone" "dentistapp" {
#  name         = "dentistapp.com."
#}

#resource "aws_route53_record" "alias_route53_record" {
#  zone_id = data.aws_route53_zone.pocketpropertiesapp.zone_id # Replace with your zone ID
#  name    = "pocketpropertiesapp.com" # Replace with your name/domain/subdomain
#  type    = "A"

#  alias {
#    name                   = module.elb.prod-elb.dns_name
#    zone_id                = module.elb.prod-elb.zone_id
#    evaluate_target_health = true
#  }
#}

#resource "aws_route53_record" "alias_route53_record-api" {
#  zone_id = data.aws_route53_zone.pocketpropertiesapp.zone_id # Replace with your zone ID
#  name    = "admin" # Replace with your name/domain/subdomain
#  type    = "A"

#  alias {
#    name                   = module.elb.prod-elb.dns_name
#    zone_id                = module.elb.prod-elb.zone_id
#    evaluate_target_health = true
#  }
#}

#resource "aws_route53_record" "alias_route53_record-admin" {
#  zone_id = data.aws_route53_zone.pocketpropertiesapp.zone_id # Replace with your zone ID
#  name    = "api." # Replace with your name/domain/subdomain
#  type    = "A"

#  alias {
#    name                   = module.elb.prod-elb.dns_name
#    zone_id                = module.elb.prod-elb.zone_id
#    evaluate_target_health = true
#  }
#}

