resource "tls_private_key" "consul_ca_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "consul_ca_cert" {
  private_key_pem = tls_private_key.consul_ca_private_key.private_key_pem

  is_ca_certificate = true

  subject {
    country      = "US"
    province     = "CA"
    locality     = "San Francisco/street=101 Second Street/postalCode=94105"
    common_name  = "Consul Agent CA ${random_string.cluster_id.id}"
    organization = "HashiCorp Inc."
  }

  validity_period_hours = 43800 //  1825 days or 5 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "cert_signing",
    "crl_signing",
    "server_auth",
    "client_auth",
  ]
}

resource "random_string" "cluster_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_uuid" "consul_bootstrap_token" {
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }

  depends_on = [module.eks]
}

resource "kubernetes_secret" "consul_secrets" {
  metadata {
    name      = "${local.cluster_id}-consul-secrets"
    namespace = "consul"
  }

  data = {
    caCert         = tls_self_signed_cert.consul_ca_cert.cert_pem,
    caKey          = tls_private_key.consul_ca_private_key.private_key_pem,
    bootstrapToken = random_uuid.consul_bootstrap_token.result,
  }

  type = "Opaque"

  depends_on = [module.eks, kubernetes_namespace.consul]
}

resource "local_file" "consul-helm-values" {
  filename = "consul/values.yaml"
  content = templatefile("consul/helm-chart.tpl", {
    datacenter     = var.datacenter,
    cluster_id     = local.cluster_id,
    consul_version = substr(var.consul_version, 1, -1),
    }
  )
}
