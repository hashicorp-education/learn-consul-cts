module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name             = "${local.cluster_id}-vpc"
  cidr             = "10.0.0.0/16"
  azs              = data.aws_availability_zones.available.names
  private_subnets  = []
  public_subnets   = ["10.0.4.0/24"]

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  create_database_subnet_group           = false

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "secgrp_default" {
  name        = "secgrp_default"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "SSH into instance"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow traffic between public and private subnets in the supernet"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description      = "allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "secgrp_default"
  }
}

// EC2 instance image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

// SSH RSA key
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Key pair
resource "aws_key_pair" "key-instances" {
  key_name   = "${var.cluster_id}-tls-key"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "key_instances_key" {
  content         = tls_private_key.pk.private_key_pem
  filename        = "./tls-key.pem"
  file_permission = "0400"
}
