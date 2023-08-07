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

output "subnet_id" {
  value       = module.vpc.public_subnets[0]
  description = "AWS public subnet"
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cts_instance" {
  value       = aws_instance.cts[0].public_ip
  description = "CTS instance public IP"
}

output "app_instance_public_ip" {
  value       = aws_instance.application[0].public_ip
  description = "App instance public IP"
  }

output "app_instance_private_ip" {
  value       = aws_instance.application[0].private_ip
  description = "App instance private IP"
}

output "consul_token" {
  sensitive = true
  value = random_uuid.consul_bootstrap_token.result
  description = "Consul bootstrap token"
}

#output "cts_via_jumphost" {
#  value = "ssh -i ${local_file.key_instances_key.filename} -J ubuntu@${aws_instance.jumphost[0].public_ip} ubuntu@${aws_instance.cts[0].private_ip}"
#}