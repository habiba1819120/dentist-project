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




###########
####    EC2 Role 
###########

#######Create an IAM Policy and Role for ECR
resource "aws_iam_policy" "ecr-policy" {
  name        = "ECR--policy"
  description = "Provides permission to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action": [
            "ecr:*"
        ]
        Effect   = "Allow"
        Resource: "*"
      },
    ]
  })
}

#Create an IAM Role
resource "aws_iam_role" "ec2-role" {
  name = "ec2--Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ec2-ecr-attach" {
  name       = "ec2-ecr-attachment"
  roles      = [aws_iam_role.ec2-role.name]
  policy_arn = aws_iam_policy.ecr-policy.arn
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2-role.name
}


##########################################
##########      PROD ENV
###########################################

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

module "prod_ec2" {
  for_each = local.prod_ec2s
  source = "./ec2"
  name = each.key
  settings = each.value  
  subnets = aws_subnet.prod_subnet
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  vpc_security_group_ids = [aws_security_group.prod_web_sg.id]
}

"data "aws_eip" "aws_eip" {
#  for_each =  local.prod_ec2s
#  id = local.prod_aws_eips[each.key]
#}

#Associate EIP with EC2 Instance
#resource "aws_eip_association" "aws_eip_association" {
#  for_each =  module.prod_ec2
#  instance_id = module.prod_ec2[each.key].ec2_instance[0].id
#  allocation_id = data.aws_eip.aws_eip[each.key].id
#}


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
