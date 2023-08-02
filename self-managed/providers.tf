terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.18.0"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
  }

  provider_meta "hcp" {
    module_name = "hcp-consul"
  }  
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

locals {
  cluster_id = "${var.cluster_id}-${random_string.cluster_id.id}"
}