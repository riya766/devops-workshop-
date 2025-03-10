provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "demo-server2" {
ami = "ami-0c2e61fdcb5495691"
instance_type = "t3.micro"
key_name = "TF" 
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Allow ssh  inbound traffic and all outbound traffic"
 

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




resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

