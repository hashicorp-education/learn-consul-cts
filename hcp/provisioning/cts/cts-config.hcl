consul {
  address = "localhost:8500"
  token   = "${cts_token}"
}

log_level   = "INFO"
working_dir = "sync-tasks"
port        = 8558

syslog {}

buffer_period {
  enabled = true
  min     = "5s"
  max     = "20s"
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
  variable_files = ["cts-jumphost-module.tfvars"]

  condition "services" {
    regexp = "^nginx.*"
    use_as_module_input = true
  }
}
