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

}




