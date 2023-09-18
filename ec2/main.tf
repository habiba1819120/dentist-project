variable "name" {}
variable "settings" {}
variable "subnets" {}
variable "vpc_security_group_ids" {}

# Create EC2 Instances
resource "aws_instance" "ec2_instance" {
  count = var.settings.amount 

  key_name =  var.settings.key_name 
  ami           = var.settings.ami  # Update with appropriate AMI ID
  instance_type =  var.settings.type  # Update with appropriate instance type
  associate_public_ip_address = true
  subnet_id     = var.subnets[count.index].id 
  tags = {
    Name = var.name
  }
 user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    # Install OpenSSH if not already installed
    if ! dpkg -l | grep -q "openssh-server"; then
      sudo apt-get install -y openssh-server
    fi
    # Start and enable OpenSSH service
    sudo systemctl start ssh
    sudo systemctl enable ssh
    # Install Nginx, Docker, AWS CLI, and Java as before
    sudo apt-get install -y nginx docker.io default-jre
    sudo apt-get install -y awscli
    sudo apt-get install -y openjdk-11-jdk


    # Configure AWS CLI (replace with your AWS credentials and region)
    aws configure set aws_access_key_id AKIAV2OBSZ2QGRDPF2K5
    aws configure set aws_secret_access_key CbnW4Nud8+Thvl2/WgbLiJ7pbs/RKgZfCYs2Y7vp
    aws configure set region us-east-1
  EOF

}




