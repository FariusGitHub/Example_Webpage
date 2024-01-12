provider "aws" {
  region     = "us-east-1"
  access_key = jsondecode(file("aws.credentials")).access
  secret_key = jsondecode(file("aws.credentials")).secret
}

resource "aws_vpc" "vpc-project6" {
    cidr_block = "10.2.0.0/16"
    tags = {
    Name = "vpc-project6"
    }
}

resource "aws_subnet" "pub-subnet" {
    vpc_id = aws_vpc.vpc-project6.id
    cidr_block = "10.2.254.0/24"
    tags = {
    Name = "pub-subnet"
    }
}

resource "aws_internet_gateway" "igw-vpc-project6" {
    vpc_id = aws_vpc.vpc-project6.id
    tags = {
    Name = "igw-vpc-project6"
    }
}

resource "aws_route_table" "rt-pub-project6" {
vpc_id = aws_vpc.vpc-project6.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw-vpc-project6.id
}
tags = {
Name = "rt-pub-project6"
}
}

resource "aws_route_table_association" "rt-pub_association-project6" {
    subnet_id = aws_subnet.pub-subnet.id
    route_table_id = aws_route_table.rt-pub-project6.id
}

resource "aws_security_group" "sg_api_project6" {
  name        = "sg_api_project6"
  description = "sg_api_project6"
  vpc_id      = aws_vpc.vpc-project6.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  ingress {
    from_port   = 5000
    to_port     = 5000
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
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }   

   ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  

  tags = {
    Name = "sg_api_project6"
  }
}

resource "aws_instance" "project6" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.small"
  key_name      = "wcd-project"
  subnet_id     = aws_subnet.pub-subnet.id
  vpc_security_group_ids = [
    aws_security_group.sg_api_project6.id
  ]
  associate_public_ip_address = true
  tags = {
    Name = "project6"
  }
  user_data = file("install-packages.sh")
}
