output "consul_token" {
  sensitive = true
  value = random_uuid.consul_bootstrap_token.result
  description = "Consul bootstrap token"
}

output "cts_instance_ip" {
  value = aws_instance.cts[0].public_ip
  description = "Public IP of the CTS Instance"
}

output "next_steps" {
  value = <<-NEXTSTEPS
  You can now access your CTS instance by running:
  ssh -i ${local_file.key_instances_key.filename} ubuntu@${aws_instance.cts[0].public_ip}
  NEXTSTEPS
}