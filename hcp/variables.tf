variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "learn-cts"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "hvn_region" {
  type        = string
  description = "The HCP region to create resources in"
  default     = "us-west-2"
}

variable "hvn_id" {
  type        = string
  description = "The name of your HCP HVN"
  default     = "learn-cts"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}

variable "consul_tier" {
  type        = string
  description = "The HCP Consul tier to use when creating a Consul cluster"
  default     = "development"
}

variable "consul_version" {
  type        = string
  description = "The HCP Consul version"
  default     = "v1.15.2"
}

variable "cts_version" {
  type        = string
  description = "CTS version to install"
  default     = "v0.6.0+ent"
}