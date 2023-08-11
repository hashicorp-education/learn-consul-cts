## EC2 Jumphost with Security Groups module for Consul Terraform Sync

This Terraform module creates an EC2 jumphost instance and a related security group that allows SSH towards every service from the Consul catalog. Using the module in automation with [Consul Terraform Sync](https://www.consul.io/docs/nia) will dynamically add or remove firewall destination rules from the security group based on [Consul service discovery](https://www.consul.io/).

## Feature

The module creates an EC2 instance, and a security group applied to the instance that allows outbound SSH access. The module executes on the default services condition, when there are any changes to the instances of the specified services.

## Requirements

### Ecosystem Requirements

| Ecosystem | Version |
|-----------|---------|
| [consul](https://www.consul.io/downloads) | >= 1.16 |
| [consul-terraform-sync](https://www.consul.io/docs/nia) | >= 0.1.0 |
| [terraform](https://www.terraform.io) | >= 0.13 |

### Terraform Providers

| Name | Version |
|------|---------|
| hashicorp/aws | ~> 3.43 |

## Setup

Prerequisites:

- a working set of credetials for AWS is the only prerequisite
- a deployed VPC with a subnet in an AWS region

Here's a sample invocation of the module to track only service instances with an `nginx` name:

```
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
```

## Usage

<!-- begin template instructions replace -->

Highlight any required [input variables](https://consul.io/docs/nia/configuration#variable_files), [user-defined metadata](https://consul.io/docs/nia/configuration#cts_user_defined_meta), or [provided input variables](https://consul.io/docs/nia/terraform-modules#optional-input-variables) and provide an example configuration for Consul Terraform Sync for your module.

<!-- end -->

| User-defined meta | Required | Description |
|-------------------|----------|-------------|
| policy_name | true | The name of an existing policy to apply to the address group for the service |

**User Config for Consul Terraform Sync**

example.hcl
```hcl
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
```