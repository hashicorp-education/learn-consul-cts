# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
  }
}

locals {
  consul_services = {
    for id, s in var.services : s.name => s...
  }

  services_flattened_list = flatten([
    for k, v in var.services : [
      "${v.node_address}/32"
    ]
  ])

  region    = var.region
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id
  key_name  = var.key_name
}

provider "aws" {
  region = local.region
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

resource "aws_security_group" "secgrp-jumphost" {
  name        = "secgrp-jumphost"
  description = "Jumphost-specific security group"
  vpc_id      = local.vpc_id

  tags = {
    Name       = "sg-jumphost"
    CtsJumphostModule = "true"
  }
}

resource "aws_security_group_rule" "ingress-jumphost-rule" {
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.secgrp-jumphost.id
}

resource "aws_security_group_rule" "egress-jumphost-rules" {
  for_each = toset(local.services_flattened_list)

  from_port         = 22
  to_port           = 22
  cidr_blocks       = [each.key]
  protocol          = "tcp"
  type              = "egress"
  security_group_id = aws_security_group.secgrp-jumphost.id
 }

// Consul client instance
resource "aws_instance" "jumphost" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = local.subnet_id
  vpc_security_group_ids = [
    aws_security_group.secgrp-jumphost.id
  ]
  key_name = local.key_name

  tags = {
    Name       = "jumphost-${count.index}"
    CtsJumphostModule = "true"
  }
}
