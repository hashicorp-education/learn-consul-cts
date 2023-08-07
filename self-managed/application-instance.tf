// application instance
resource "aws_instance" "application" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id
  ]
  key_name = aws_key_pair.key-instances.key_name

  user_data = templatefile("${path.module}/scripts/application-instance/user_data.sh", {
    setup = base64gzip(templatefile("${path.module}/scripts/application-instance/setup.sh", {
      consul_ca = base64encode(tls_self_signed_cert.consul_ca_cert.cert_pem),
      consul_config = base64encode(templatefile("${path.module}/scripts/application-instance/consul-client.json", {
        datacenter = var.datacenter,
        retry_join = aws_instance.cts[0].private_ip,
        consul_default_token = random_uuid.consul_bootstrap_token.result
      })),
      consul_acl_token = random_uuid.consul_bootstrap_token.result,
      consul_version   = var.consul_version,
      consul_service = base64encode(templatefile("${path.module}/scripts/application-instance/service", {
        service_name = "consul",
        service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      vpc_cidr    = module.vpc.vpc_cidr_block,
    })),
  })

  tags = {
    Name = "application-${count.index}"
  }
}
