variable "access_key" {}
variable "secret_key" {}
variable "AccessSubnetCIDR" {}

provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = "ap-northeast-1"
}

resource "aws_vpc" "test-VPC" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "false"
    tags = {
      Name = "test-VPC"
    }
}

resource "aws_internet_gateway" "test-IGW" {
    vpc_id = aws_vpc.test-VPC.id
    # depends_on = [aws_vpc.test-VPC]
}

resource "aws_subnet" "test-pub-subnet1" {
  vpc_id     = aws_vpc.test-VPC.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "test-pub-subnet1"
  }
}

resource "aws_subnet" "test-private-subnet2" {
  vpc_id     = aws_vpc.test-VPC.id
  cidr_block = "10.1.2.0/24"

  tags = {
    Name = "test-private-subnet2"
  }
}

resource "aws_route_table" "test-pub-route" {
  vpc_id = aws_vpc.test-VPC.id

  route {
    # cidr_block = "10.1.1.0/24"
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-IGW.id
  }

  tags = {
    Name = "test-pub-route"
  }
}

resource "aws_route_table" "test-private-route" {
  vpc_id = aws_vpc.test-VPC.id

  # route {
  #   cidr_block = "10.1.2.0/24"
  #   gateway_id = aws_internet_gateway.test-IGW.id
  # }

  tags = {
    Name = "test-private-route"
  }
}

resource "aws_route_table_association" "test-pub-subnet1" {
  subnet_id      = aws_subnet.test-pub-subnet1.id
  route_table_id = aws_route_table.test-pub-route.id
}

resource "aws_route_table_association" "test-private-subnet2" {
  subnet_id      = aws_subnet.test-private-subnet2.id
  route_table_id = aws_route_table.test-private-route.id
}

resource "aws_security_group" "test-pub-sg" {
  vpc_id = aws_vpc.test-VPC.id

  ingress {
    protocol  = "tcp"
    # self      = true
    from_port = 22
    to_port   = 22
    cidr_blocks = [var.AccessSubnetCIDR]
  }

  ingress {
    protocol  = "tcp"
    # self      = true
    from_port = 80
    to_port   = 80
    cidr_blocks = [var.AccessSubnetCIDR]
  }

  ingress {
    protocol  = "-1"
    # self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = [aws_subnet.test-private-subnet2.cidr_block]
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = {
    Name = "test-pub-sg"
  }
}

resource "aws_security_group" "test-private-sg" {
  vpc_id = aws_vpc.test-VPC.id

  ingress {
    protocol  = "-1"
    # self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = [aws_subnet.test-pub-subnet1.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [aws_subnet.test-pub-subnet1.cidr_block]
  }

      tags = {
    Name = "test-private-sg"
  }
}


resource "aws_instance" "test-pub-ec2" {
    ami                         = "ami-0992fc94ca0f1415a"
    # availability_zone           = "ap-northeast-1c"
    # ebs_optimized               = false
    instance_type               = "t2.nano"
    # monitoring                  = false
    key_name                    = "takuya-yn"
    subnet_id                   = aws_subnet.test-pub-subnet1.id
    vpc_security_group_ids      = [aws_security_group.test-pub-sg.id]
    associate_public_ip_address = true
    # private_ip                  = "10.0.0.10"
    # source_dest_check           = true

    # root_block_device {
    #     volume_type           = "gp2"
    #     volume_size           = 20
    #     delete_on_termination = true
    # }

    tags = {
        "Name" = "test-pub-ec2"
    }
}

resource "aws_instance" "test-private-ec2" {
    ami                         = "ami-0992fc94ca0f1415a"
    # availability_zone           = "ap-northeast-1c"
    # ebs_optimized               = false
    instance_type               = "t2.nano"
    # monitoring                  = false
    key_name                    = "takuya-yn"
    subnet_id                   = aws_subnet.test-private-subnet2.id
    vpc_security_group_ids      = [aws_security_group.test-private-sg.id]
    associate_public_ip_address = false
    # private_ip                  = "10.0.0.10"
    # source_dest_check           = true

    # root_block_device {
    #     volume_type           = "gp2"
    #     volume_size           = 20
    #     delete_on_termination = true
    # }

    tags = {
        "Name" = "test-private-ec2"
    }
}