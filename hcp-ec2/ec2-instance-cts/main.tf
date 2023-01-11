locals {
  aws_region = var.aws_region
  hvn_region = var.aws_region
  consul_config = file("${path.module}/${var.consul_config_file_path}")
  consul_ca = file("${path.module}/${var.consul_ca_file_path}")
  consul_acl_token = var.hcp_consul_root_token
  consul_version = var.consul_version
}

provider "aws" {
  region = local.aws_region
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

// EC2 instance
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


// SSH RSA key
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Key pair
resource "aws_key_pair" "consul_client" {
  key_name   = "${var.cluster_id}-consul-client"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "consul_client_key" {
    content  = tls_private_key.pk.private_key_pem
    filename = "./consul-client.pem"
    file_permission = "0400"
}

// Security groups
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description      = "SSH into instance"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

// Consul client instance
resource "aws_instance" "consul_client" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  subnet_id                   = var.subnet_id
  vpc_security_group_ids = [
    var.hcp_consul_security_group_id,
    aws_security_group.allow_ssh.id
  ]
  key_name = aws_key_pair.consul_client.key_name

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    setup = base64gzip(templatefile("${path.module}/scripts/setup.sh", {
      consul_ca        = base64encode(local.consul_ca),
      consul_config    = base64encode(local.consul_config),
      consul_acl_token = local.consul_acl_token,
      consul_version   = local.consul_version,
      consul_service = base64encode(templatefile("${path.module}/scripts/service", {
        service_name = "consul",
        service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      cts_version = var.cts_version,
      vpc_cidr = var.vpc_cidr_block,
    })),
  })

  tags = {
    Name = "hcp-consul-client-${count.index}"
  }
}
