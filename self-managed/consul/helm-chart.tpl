global:
  enabled: false
  name: consul
  datacenter: ${datacenter}
  image: "hashicorp/consul:${consul_version}"
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: ${cluster_id}-consul-secrets
      secretKey: bootstrapToken
  #gossipEncryption:
  #  autoGenerate: true
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: ${cluster_id}-consul-secrets
      secretKey: caCert
    caKey:
      secretName: ${cluster_id}-consul-secrets
      secretKey: caKey

server:
  enabled: true
  replicas: 1
  exposeGossipAndRPCPorts: true
  ports:
    serflan:
      port: 9301

client:
  exposeGossipPorts: true

ui:
  enabled: true

connectInject:
  transparentProxy:
    defaultEnabled: true
  enabled: true
  default: true
  centralConfig:
    enabled: true
  consulNode:
    meta:
      terraform-module: "hcp-eks-client"