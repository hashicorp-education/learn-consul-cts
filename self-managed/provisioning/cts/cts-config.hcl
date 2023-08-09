consul {
  address = "localhost:8500"
  token   = "${cts_token}"
}

driver "terraform" {
  log         = false
  persist_log = true
  path        = ""

  backend "consul" {
    gzip = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
  }
}

terraform_provider "aws" {
}

task {
  name      = "jumphost-ssh"
  module    = "./cts-jumphost-module"
  providers = ["aws"]

  module_input "services" {
    regexp = "nginx.*"
    cts_user_defined_meta = {
      vpc_id = "${vpc_id}"
      region = "${region}"
      subnet_id = "${subnet_id}"
    }
  }
}
