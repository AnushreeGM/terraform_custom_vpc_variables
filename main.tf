terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 4.0"
        }
    }
}
provider "aws" {
    region = var.my_region
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_vpc" "UST-B-VPC" {
    cidr_block = var.my_vpc_cidr
    tags = {
        Name = "UST-B-VPC-tag"
    }
}

resource "aws_internet_gateway" "UST-B-IGW" {
    vpc_id = aws_vpc.UST-B-VPC.id
    tags = {
        Name = "UST-B-IGW-tag"
    }
}

resource "aws_subnet" "UST-B-PubSub" {
    vpc_id = aws_vpc.UST-B-VPC.id
    cidr_block = var.my_public_subnet_cidr
    availability_zone = var.my_public_availability_zone
    tags = {
        Name = "UST-A-PubSub-tag"
    }
}

resource "aws_subnet" "UST-B-PriSub" {
    vpc_id = aws_vpc.UST-B-VPC.id
    cidr_block = var.my_private_subnet_cidr
    availability_zone = var.my_private_availability_zone
    tags = {
        Name = "UST-B-PriSub-tag"
    }
}

resource "aws_eip" "UST-B-EIP" {
    vpc = true 
    tags = {
        Name = "UST-B-EIP-tag"
    }
}
resource "aws_nat_gateway" "UST-B-NAT" {
    allocation_id = aws_eip.UST-B-EIP.id
    subnet_id = aws_subnet.UST-B-PubSub.id
    tags = {
        Name = "UST-B-NAT-tag"
    } 
}
resource "aws_route_table" "UST-B-PubSub-RT" {
    vpc_id = aws_vpc.UST-B-VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.UST-B-IGW.id
    }
    tags = {
        Name = "UST-B-PubSub-RT-tag"
    }
}
resource "aws_route_table" "UST-B-PrivSub-RT" {
    vpc_id = aws_vpc.UST-B-VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.UST-B-NAT.id
    }
    tags = {
        Name = "UST-B-PrivSub-RT-tag"
    } 
}
resource "aws_route_table_association" "UST-B-PubSub-RT-Assoc" {
    subnet_id = aws_subnet.UST-B-PubSub.id
    route_table_id = aws_route_table.UST-B-PubSub-RT.id
}
resource "aws_route_table_association" "UST-B-PrivSub-RT-Assoc" {
    subnet_id = aws_subnet.UST-B-PriSub.id
    route_table_id = aws_route_table.UST-B-PrivSub-RT.id
  
}
resource "aws_security_group" "UST-B-SG" {
    vpc_id = aws_vpc.UST-B-VPC.id
    name = "UST-B-SG"
    description = "Security group for UST-B"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "UST-B-SG-tag"
    }
}
resource "aws_network_acl" "UST-B-NACL" {
    vpc_id = aws_vpc.UST-B-VPC.id
    ingress {
        protocol = "-1"
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        action = "allow"
        rule_no = 100
        cidr_block = "0.0.0.0/0"
    } 
}
resource "aws_network_acl_association" "NACL-PubSub" {
    subnet_id = aws_subnet.UST-B-PubSub.id
    network_acl_id = aws_network_acl.UST-B-NACL.id
}
resource "aws_network_acl_association" "NACL-PriSub" {
    subnet_id = aws_subnet.UST-B-PriSub.id
    network_acl_id = aws_network_acl.UST-B-NACL.id
}
resource "aws_instance" "UST-B-VPC-PubSub" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    subnet_id = aws_subnet.UST-B-PubSub.id
    vpc_security_group_ids = [aws_security_group.UST-B-SG.id]
    associate_public_ip_address = true
    user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>This is your Public Instance from Custom VPC UST-B-VPC</h1></body></html>" > /var/www/html/index.html
              EOF
    tags = {
        Name = "UST-B-VPC-PubSub-tag"
    }
}

resource "aws_instance" "UST-B-VPC-PriSub" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    subnet_id = aws_subnet.UST-B-PriSub.id
    vpc_security_group_ids = [aws_security_group.UST-B-SG.id]
    user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>This is your Private Instance from Custom VPC UST-B-VPC</h1></body></html>" > /var/www/html/index.html
              EOF
    tags = {
        Name = "UST-B-VPC-PrivSub-tag"
    }
  
}
output "public_ec2_public_ip" {
    value = aws_instance.UST-B-VPC-PubSub.public_ip
}
output "public_ec2_private_ip" {
    value = aws_instance.UST-B-VPC-PubSub.private_ip
}
output "private_ec2_private_ip" {
    value = aws_instance.UST-B-VPC-PriSub.private_ip 
}
output "private_ec2_instance_id" {
    value = aws_instance.UST-B-VPC-PriSub.id
  
}
