# resource "aws_security_group" "secgrp-jumphost" {
#   name        = "secgrp-jumphost"
#   description = "Jumphost-specific security group"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description      = "SSH into instance"
#     from_port        = 22
#     to_port          = 22
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"] #todo application IPs
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   egress {
#     description      = "allow all egress"
#     from_port        = 0
#     to_port          = 0
#     protocol         = -1
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "sg-jumphost"
#   }
# }

# // Consul client instance
# resource "aws_instance" "jumphost" {
#   count                       = 1
#   ami                         = data.aws_ami.ubuntu.id
#   instance_type               = "t3.micro"
#   associate_public_ip_address = true
#   subnet_id                   = module.vpc.public_subnets[0]
#   vpc_security_group_ids = [
#     aws_security_group.secgrp-jumphost.id
#   ]
#   key_name = aws_key_pair.key-instances.key_name

#   user_data = templatefile("${path.module}/scripts/user_data.sh", {
#     setup = base64gzip(templatefile("${path.module}/scripts/setup.sh", {
#       consul_ca = base64encode(tls_self_signed_cert.consul_ca_cert.cert_pem),
#       consul_config = base64encode(templatefile("${path.module}/scripts/consul-config.json", {
#         datacenter = var.datacenter,
#       })),
#       consul_acl_token = random_uuid.consul_bootstrap_token.result,
#       consul_version   = var.consul_version,
#       consul_service = base64encode(templatefile("${path.module}/scripts/service", {
#         service_name = "consul",
#         service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
#       })),
#       cts_version = var.cts_version,
#       vpc_cidr    = module.vpc.vpc_cidr_block,
#     })),
#   })

#   tags = {
#     Name = "jumphost-${count.index}"
#   }
# }
