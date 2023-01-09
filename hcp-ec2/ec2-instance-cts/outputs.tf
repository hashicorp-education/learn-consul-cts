output "ec2_client" {
  value       = aws_instance.consul_client[0].public_ip
  description = "EC2 public IP"
}

output "consul_url" {
  value = data.hcp_consul_cluster.selected.public_endpoint ? (
    data.hcp_consul_cluster.selected.consul_public_endpoint_url
    ) : (
    data.hcp_consul_cluster.selected.consul_private_endpoint_url
  )
  description = "HCP Consul UI"
}

output "consul_root_token" {
  value       = hcp_consul_cluster_root_token.token.secret_id
  sensitive   = true
  description = "HCP Consul root ACL token"
}
