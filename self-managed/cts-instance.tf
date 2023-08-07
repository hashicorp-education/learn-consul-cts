resource "tls_private_key" "consul_ca_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "consul_ca_cert" {
  private_key_pem = tls_private_key.consul_ca_private_key.private_key_pem

  is_ca_certificate = true

  subject {
    country      = "US"
    province     = "CA"
    locality     = "San Francisco/street=101 Second Street/postalCode=94105"
    common_name  = "Consul Agent CA ${random_string.cluster_id.id}"
    organization = "HashiCorp Inc."
  }

  validity_period_hours = 43800 //  1825 days or 5 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "cert_signing",
    "crl_signing",
    "server_auth",
    "client_auth",
  ]
}

resource "random_string" "cluster_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_uuid" "consul_bootstrap_token" {
}

resource "aws_iam_policy" "policy_manage_instances" {
  description = "An IAM policy that allows listing information for all EC2 objects and launching EC2 instances in a specific subnet. This policy also provides the permissions necessary to complete this action on the console."
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "ec2:*",
          "Effect" : "Allow",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "elasticloadbalancing:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "cloudwatch:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "autoscaling:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:CreateServiceLinkedRole",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : [
                "autoscaling.amazonaws.com",
                "ec2scheduled.amazonaws.com",
                "elasticloadbalancing.amazonaws.com",
                "spot.amazonaws.com",
                "spotfleet.amazonaws.com",
                "transitgateway.amazonaws.com"
              ]
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : "arn:aws:iam::123456789012:role/*"
        }
      ]
    }
  )
}

resource "aws_iam_role" "role_manage_instances" {
  name = "role_manage_instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "policy_attachment_instances" {
  name       = "policy_attachment_instances"
  roles      = [aws_iam_role.role_manage_instances.name]
  policy_arn = aws_iam_policy.policy_manage_instances.arn
}

resource "aws_iam_instance_profile" "profile_instances" {
  name = "profile_instances"
  role = aws_iam_role.role_manage_instances.name
}


resource "aws_instance" "cts" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.profile_instances.name
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id
  ]
  key_name = aws_key_pair.key-instances.key_name

  user_data = templatefile("${path.module}/scripts/cts-instance/user_data.sh", {
    setup = base64gzip(templatefile("${path.module}/scripts/cts-instance/setup.sh", {
      consul_ca = base64encode(tls_self_signed_cert.consul_ca_cert.cert_pem),
      consul_config = base64encode(templatefile("${path.module}/scripts/cts-instance/consul-config.json", {
        datacenter = var.datacenter,
      })),
      consul_acl_token = random_uuid.consul_bootstrap_token.result,
      consul_version   = var.consul_version,
      consul_service = base64encode(templatefile("${path.module}/scripts/cts-instance/service", {
        service_name = "consul",
        service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      cts_config = base64encode(templatefile("${path.module}/cts/cts-config.hcl", {
        cts_token = random_uuid.consul_bootstrap_token.result,
        vpc_id    = module.vpc.vpc_id,
        region    = var.aws_region,
        subnet_id = module.vpc.public_subnets[0],
      })),
      cts_version = var.cts_version,
      vpc_cidr    = module.vpc.vpc_cidr_block,
    })),
  })

  provisioner "file" {
    source      = "cts"
    destination = "/home/ubuntu"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = local_file.key_instances_key.content
    }

  }

  tags = {
    Name = "cts-${count.index}"
  }
}
