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

provider "hcp" {
}

provider "consul" {
  address = hcp_consul_cluster.main.consul_public_endpoint_url
  token   = hcp_consul_cluster_root_token.token.secret_id
}

locals {
  cluster_id = "${var.cluster_id}-${random_string.cluster_id.id}"
  hvn_id     = "${var.hvn_id}-${random_string.cluster_id.id}"
}