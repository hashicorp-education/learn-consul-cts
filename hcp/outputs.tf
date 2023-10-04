output "aws_region" {
  description = "AWS Region"
  value = var.aws_region
}

output "consul_token" {
  sensitive = true
  value = hcp_consul_cluster.main.consul_root_token_secret_id
  description = "Consul root token"
}

output "cts_instance_ip" {
  value = aws_instance.cts[0].public_ip
  description = "Public IP of the CTS Instance"
}

output "app_instance_ips" {
  value = aws_instance.application.*.private_ip
  description = "Private IPs of the App Instances"
}

output "next_steps" {
  value = <<-NEXTSTEPS
  You can now access your CTS instance by running:
  ssh -i ${local_file.key_instances_key.filename} ubuntu@${aws_instance.cts[0].public_ip}  
  NEXTSTEPS
}