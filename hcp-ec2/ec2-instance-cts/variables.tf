variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
}

variable "vpc_cidr_block" {
  type        = string
  description = "AWS CIDR block"
}

variable "subnet_id" {
  type        = string
  description = "AWS subnet (public)"
}

variable "cluster_id" {
  type        = string
  description = "HCP Consul ID"
}

variable "hcp_consul_security_group_id" {
  type        = string
  description = "AWS Security group for HCP Consul"
}

variable "hcp_consul_root_token" {
  type = string
  description = "HCP Consul root token"
  sensitive = true
}

variable "consul_version" {
  type = string
  description = "Consul version to deploy on the EC2 instance"
  default = "v1.12.8+ent"
}

variable "consul_ca_file_path" {
  type = string
  description = "Relative path to the Consul CA file used to join a cluster"
  default = "../infrastructure/ca.pem"
}

variable "consul_config_file_path" {
  type = string
  description = "Relative path to the Consul config file used to join a cluster"
  default = "../infrastructure/client_config.json"
}

variable "cts_version" {
  type        = string
  description = "CTS version to install"
  default     = "v0.6.0+ent"
}

variable "aws_region" {
  type = string
  description = "AWS region"
  default = "us-west-2"
}
