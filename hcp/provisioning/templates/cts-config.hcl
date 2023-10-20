consul {
  address = "localhost:8500"
  token   = ""
}

log_level   = "INFO"
working_dir = "/opt/consul-nia/sync-tasks"
port        = 8558
id          = "cts-0"

syslog {}

buffer_period {
  enabled = true
  min     = "1m"
  max     = "3m"
}

driver "terraform" {
  log         = false
  persist_log = true
  path        = "/opt/consul-nia/"

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
  module    = "/opt/consul-nia/cts-jumphost-module"
  providers = ["aws"]
  variable_files = ["/opt/consul-nia/cts-jumphost-module.tfvars"]

  condition "services" {
    regexp = "^nginx.*"
    use_as_module_input = true
  }
}
