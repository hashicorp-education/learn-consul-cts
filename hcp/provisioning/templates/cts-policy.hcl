## Consul CTS service privileges

# Permission for CTS to register itself as a service in the Consul catalog
service "consul-terraform-sync" {
  policy = "write"
}

## Consul KV privileges

# Permission for CTS to write the Terraform state in the default Consul KV path
key_prefix "consul-terraform-sync/" {
  policy = "write"
}

# Permission for CTS to lock a semaphore session for all possible node names.
# For a restrictive environment, this should be a Node name (session) or a Node name prefix (session_prefix)
session_prefix "" {
  policy = "write"
}

## Consul catalog privileges

# Permission for CTS to observe the nginx service for catalog changes
service_prefix "nginx" {
  policy = "read"
}

# Permission for CTS to observe services on any node
node_prefix "" {
  policy = "read"
}
