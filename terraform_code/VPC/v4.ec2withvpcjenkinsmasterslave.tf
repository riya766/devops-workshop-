provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "dpp-vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "dpp-vpc"
  }
}

resource "aws_subnet" "dpp-public-subnt-01" {
  vpc_id                  = aws_vpc.dpp-vpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"

  tags = {
    Name = "dpp-public-subnet-01"
  }
}

resource "aws_subnet" "dpp-public-subnt-02" {
  vpc_id                  = aws_vpc.dpp-vpc.id
  cidr_block              = "10.10.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1b"

  tags = {
    Name = "dpp-public-subnet-02"
  }
}

resource "aws_internet_gateway" "dpp-igw" {
  vpc_id = aws_vpc.dpp-vpc.id
  tags = {
    Name = "dpp-igw"
  }
}

resource "aws_route_table" "dpp-public-rt" {
  vpc_id = aws_vpc.dpp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpp-igw.id
  }
}

resource "aws_route_table_association" "dpp-rta-public-subnet-01" {
  subnet_id      = aws_subnet.dpp-public-subnt-01.id
  route_table_id = aws_route_table.dpp-public-rt.id
}

resource "aws_route_table_association" "dpp-rta-public-subnet-02" {
  subnet_id      = aws_subnet.dpp-public-subnt-02.id
  route_table_id = aws_route_table.dpp-public-rt.id
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.dpp-vpc.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh-access" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "jenkins-access" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All ports
}

resource "aws_instance" "demo-server" {
  for_each = toset(["jenkins-master", "jenkins-slave", "ansible"])

  ami                  = "ami-09a9858973b288bdd"
  instance_type        = "t3.micro"
  key_name             = "TF"
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  
  subnet_id = aws_subnet.dpp-public-subnt-01.id  # Agar har instance ko alag subnet me rakhna hai, to condition lagani padegi
  
  tags = {
    Name = each.key
  }
}


# Security Group Module
module "sgs" {
  source = "../sg_eks"
  vpc_id = aws_vpc.dpp-vpc.id
}

# EKS Cluster Module
module "eks" {
  source     = "../eks"
  vpc_id     = aws_vpc.dpp-vpc.id
  subnet_ids = [aws_subnet.dpp-public-subnt-01.id, aws_subnet.dpp-public-subnt-02.id]
  sg_ids     = module.sgs.security_group_public
}

