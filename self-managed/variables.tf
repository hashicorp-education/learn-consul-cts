variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "learn-cts"
}

variable "datacenter" {
  type = string
  description = "Name of the Consul datacenter"
  default = "dc1"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "consul_version" {
  type        = string
  description = "The HCP Consul version"
  default     = "v1.15.2"
}

variable "cts_version" {
  type        = string
  description = "CTS version to install"
  default     = "v0.6.0"
}