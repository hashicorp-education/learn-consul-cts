output "ec2_client" {
  value       = aws_instance.consul_client[0].public_ip
  description = "EC2 public IP"
}

output "consul_root_token" {
  value       = var.hcp_consul_root_token
  sensitive   = true
  description = "HCP Consul root ACL token"
}
