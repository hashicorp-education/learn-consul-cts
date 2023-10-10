terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  cluster_id = "${var.cluster_id}-${random_string.cluster_id.id}"
}