variable "application_instances_amount" {
  type = number
  description = "The amount of application instances to deploy"
  default = 1
}

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
  default     = "us-east-2"
}

variable "consul_version" {
  type        = string
  description = "The HCP Consul version"
  default     = "v1.16.2"
}

variable "cts_version" {
  type        = string
  description = "CTS version to install"
  default     = "v0.7.0"
}