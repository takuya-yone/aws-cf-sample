variable "access_key" {}
variable "secret_key" {}
variable "AccessSubnetCIDR" {}
variable "region" {
  default = "ap-northeast-1"
}

provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = var.region
}

resource "aws_vpc" "test-VPC" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    tags = {
      Name = "test-VPC"
    }
}

resource "aws_internet_gateway" "test-IGW" {
    vpc_id = aws_vpc.test-VPC.id
    # depends_on = [aws_vpc.test-VPC]
}

resource "aws_subnet" "test-pub-subnet" {
  vpc_id     = aws_vpc.test-VPC.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "test-pub-subnet"
  }
}

resource "aws_subnet" "test-private-subnet" {
  vpc_id     = aws_vpc.test-VPC.id
  cidr_block = "10.1.2.0/24"

  tags = {
    Name = "test-private-subnet"
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

resource "aws_route_table_association" "test-pub-subnet" {
  subnet_id      = aws_subnet.test-pub-subnet.id
  route_table_id = aws_route_table.test-pub-route.id
}

resource "aws_route_table_association" "test-private-subnet" {
  subnet_id      = aws_subnet.test-private-subnet.id
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
    cidr_blocks = [aws_subnet.test-private-subnet.cidr_block]
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
    cidr_blocks = [aws_subnet.test-pub-subnet.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    # cidr_blocks = [aws_subnet.test-pub-subnet.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }

      tags = {
    Name = "test-private-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.test-VPC.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.test-pub-sg.id]
  subnet_ids = [aws_subnet.test-private-subnet.id]
  private_dns_enabled = true
  tags = {
    Name = "test-endpoint-ssm"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.test-VPC.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.test-pub-sg.id]
  subnet_ids = [aws_subnet.test-private-subnet.id]
  private_dns_enabled = true
  tags = {
    Name = "test-endpoint-ec2messages"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.test-VPC.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.test-pub-sg.id]
  subnet_ids = [aws_subnet.test-private-subnet.id]
  private_dns_enabled = true
  tags = {
    Name = "test-endpoint-ssmmessages"
  }
}

resource "aws_iam_role" "test-EC2roleforSSM" {
  name = "test-EC2roleforSSM"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
            "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })

  tags = {
    Name = "test-EC2roleforSSM"
  }
}

resource "aws_iam_role_policy" "test-EC2policyforSSM" {
  name = "test-EC2policyforSSM"
  role   = aws_iam_role.test-EC2roleforSSM.id
  policy = jsonencode({
    "Version"= "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetEncryptionConfiguration",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "*"
        }
    ]
})

}

resource "aws_iam_instance_profile" "test-EC2instanceprofileforSSM" {
    name = "test-EC2instanceprofileforSSM"
    role = aws_iam_role.test-EC2roleforSSM.name
}

resource "aws_instance" "test-pub-ec2" {
    ami                         = "ami-0992fc94ca0f1415a"
    # availability_zone           = "ap-northeast-1c"
    # ebs_optimized               = false
    instance_type               = "t2.nano"
    # monitoring                  = false
    key_name                    = "takuya-yn"
    subnet_id                   = aws_subnet.test-pub-subnet.id
    vpc_security_group_ids      = [aws_security_group.test-pub-sg.id]
    associate_public_ip_address = true
    iam_instance_profile         = aws_iam_instance_profile.test-EC2instanceprofileforSSM.name
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
    subnet_id                   = aws_subnet.test-private-subnet.id
    vpc_security_group_ids      = [aws_security_group.test-private-sg.id]
    associate_public_ip_address = false
    iam_instance_profile         = aws_iam_instance_profile.test-EC2instanceprofileforSSM.name
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