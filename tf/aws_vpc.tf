variable "MyIP" {
  type  = string
  default = "222.227.187.111/32"
}


#----------------------------------------
# VPCの作成
#----------------------------------------
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    "Name" = "tf-vpc"
  }

}

#----------------------------------------
# パブリックサブネットの作成
#----------------------------------------
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "tf-public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    "Name" = "tf-public-subnet-c"
  }
}

#----------------------------------------
# プライベートサブネットの作成
#----------------------------------------
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "tf-private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    "Name" = "tf-private-subnet-c"
  }
}


#----------------------------------------
# インターネットゲートウェイの作成
#----------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "tf-igw"
  }
}
#----------------------------------------
# ルートテーブルの作成
#----------------------------------------
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "tf-public-rtb"
  }
}

resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "tf-private-rtb"
  }
}


#----------------------------------------
# サブネットにルートテーブルを紐づけ
#----------------------------------------
resource "aws_route_table_association" "rt_assoc_public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "rt_assoc_public_c" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "rt_assoc_private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rtb.id
}

resource "aws_route_table_association" "rt_assoc_private_c" {
  subnet_id      = aws_subnet.private_subnet_c.id
  route_table_id = aws_route_table.private_rtb.id
}

#----------------------------------------
# セキュリティグループルールの作成
#----------------------------------------
resource "aws_security_group_rule" "public-sg-rule-01" {
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.private_sg.id
  security_group_id        = aws_security_group.public_sg.id
}

resource "aws_security_group_rule" "public-sg-rule-02" {
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.public_sg.id
  security_group_id        = aws_security_group.public_sg.id
}
resource "aws_security_group_rule" "public-sg-rule-03" {
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks = [var.MyIP] 
  security_group_id        = aws_security_group.public_sg.id
}

resource "aws_security_group_rule" "private-sg-rule-01" {
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.public_sg.id
  security_group_id        = aws_security_group.private_sg.id
}

resource "aws_security_group_rule" "private-sg-rule-02" {
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.private_sg.id
  security_group_id        = aws_security_group.private_sg.id
}

#----------------------------------------
# セキュリティグループの作成
#----------------------------------------
resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "tf-public-sg"
  }
}

resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "tf-private-sg"
  }
}