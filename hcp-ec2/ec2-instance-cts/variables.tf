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

variable "cts_version" {
  type        = string
  description = "CTS version to install"
  default     = "0.6.0+ent"
}

variable "aws_region" {
  type = string
  description = "AWS region"
  default = "us-west-2"
}
