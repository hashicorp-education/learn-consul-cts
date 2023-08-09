output "consul_token" {
  sensitive = true
  value = random_uuid.consul_bootstrap_token.result
  description = "Consul bootstrap token"
}

output "next_steps" {
  value = <<-NEXTSTEPS
  Your region is: ${var.aws_region}
  Your VPC id is: ${module.vpc.vpc_id}

  You can now access your CTS instance by running:
  ssh -i ${local_file.key_instances_key.filename} ubuntu@${aws_instance.cts[0].public_ip}  
  NEXTSTEPS
}