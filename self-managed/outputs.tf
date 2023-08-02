output "kubernetes_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

# original outputs

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "AWS VPC ID"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "AWS VPC CIDR block"
}

output "vpc_public_subnets" {
  value       = module.vpc.public_subnets[0]
  description = "AWS public subnet"
}

output "vpc_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "subnet_id" {
  value       = module.vpc.public_subnets[0]
  description = "AWS public subnet"
}

output "hcp_consul_security_group_id" {
  value       = module.eks.cluster_primary_security_group_id
  description = "AWS Security group for HCP Consul"
}

output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_id
}

output "ec2_client" {
  value       = aws_instance.consul_client[0].public_ip
  description = "EC2 public IP"
}

output "consul_token" {
  sensitive = true
  value = random_uuid.consul_bootstrap_token.result
  description = "Consul bootstrap token"
}
