data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = local.cluster_id
  cluster_version = "1.26"

  cluster_addons = {
    aws-ebs-csi-driver = { most_recent = true }
  }

  subnet_ids = module.vpc.public_subnets
  vpc_id     = module.vpc.vpc_id

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    # Needed by the aws-ebs-csi-driver
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    ]
  }

  eks_managed_node_groups = {
    one = {
      name = "learn-cts-node"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

  node_security_group_additional_rules = {

    # Allow all outgoing communication
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # Allow all incoming communication
    ingress_all = {
      description      = "Node all ingress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # EKS Cluster API to Consul API webhooks
    ingress_webhooks = {
      description      = "Consul webhook API"
      protocol         = "tcp"
      from_port        = 8080
      to_port          = 8080
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # API services on ports 9090
    ingress_9090 = {
      description      = "API services"
      protocol         = "tcp"
      from_port        = 9090
      to_port          = 9090
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # API services on ports 3000
    ingress_3000 = {
      description      = "API services"
      protocol         = "tcp"
      from_port        = 3000
      to_port          = 3000
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # API services on port 5432
    ingress_5432 = {
      description      = "API services"
      protocol         = "tcp"
      from_port        = 5432
      to_port          = 5432
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # Consul ports 8500-8502
    ingress_consul = {
      description      = "Consul ports 8500-0502"
      protocol         = "tcp"
      from_port        = 8500
      to_port          = 8502
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # # Consul Dataplane communication
    # egress_grpc = {
    #   description      = "Consul gRPC"
    #   protocol         = "tcp"
    #   from_port        = 8502
    #   to_port          = 8503
    #   type             = "egress"
    #   cidr_blocks      = ["0.0.0.0/0"]
    #   ipv6_cidr_blocks = ["::/0"]
    # }
  }
}
