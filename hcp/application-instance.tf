
resource "aws_iam_policy" "policy_describe_instances" {
  description = "An IAM policy that allows listing information for all EC2 instances"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role" "role_describe_instances" {
  name = "role_describe_instances-${local.cluster_id}"

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

resource "aws_iam_policy_attachment" "policy_describe_instances" {
  name       = "policy_describe_instances-${local.cluster_id}"
  roles      = [aws_iam_role.role_describe_instances.name]
  policy_arn = aws_iam_policy.policy_describe_instances.arn
}

resource "aws_iam_instance_profile" "profile_describe_instances" {
  name = "profile_describe_instances-${local.cluster_id}"
  role = aws_iam_role.role_describe_instances.name
}

// application instance
resource "aws_instance" "application" {
  count                       = var.application_instances_amount
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.profile_describe_instances.name
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.secgrp_default.id]
  key_name                    = aws_key_pair.key-instances.key_name

  user_data = templatefile("${path.module}/provisioning/user_data.sh", {
    setup = base64gzip(templatefile("${path.module}/provisioning/setup.sh", {
      hostname = "nginx-${count.index}",
      cts_config = "",
      cts_variables = "",
      consul_ca = hcp_consul_cluster.main.consul_ca_file,
      consul_config = hcp_consul_cluster.main.consul_config_file,
      consul_acl_token = hcp_consul_cluster.main.consul_root_token_secret_id,
      consul_version   = var.consul_version,
      vpc_cidr = module.vpc.vpc_cidr_block,
    })),
  })

  tags = {
    Name                   = "application-${count.index}"
    learn-consul-cts-intro = "join"
  }

  depends_on = [ aws_instance.cts ]
}
