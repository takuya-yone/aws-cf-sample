variable "access_key" {}
variable "secret_key" {}

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

resource "aws_subnet" "test-subnet1" {
  vpc_id     = aws_vpc.test-VPC.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "test-subnet1"
  }
}

resource "aws_subnet" "test-subnet2" {
  vpc_id     = aws_vpc.test-VPC.id
  cidr_block = "10.1.2.0/24"

  tags = {
    Name = "test-subnet2"
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

resource "aws_route_table_association" "test-subnet1" {
  subnet_id      = aws_subnet.test-subnet1.id
  route_table_id = aws_route_table.test-pub-route.id
}

resource "aws_route_table_association" "test-subnet2" {
  subnet_id      = aws_subnet.test-subnet2.id
  route_table_id = aws_route_table.test-private-route.id
}