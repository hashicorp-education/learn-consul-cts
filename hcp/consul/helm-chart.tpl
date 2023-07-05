global:
  enabled: false
  name: consul
  datacenter: ${datacenter}
  image: "hashicorp/consul-enterprise:${consul_version}-ent"
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: ${cluster_id}-hcp
      secretKey: bootstrapToken
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: ${cluster_id}-hcp
      secretKey: caCert

externalServers:
  enabled: true
  hosts: [${consul_hosts}]
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${k8s_api_endpoint}:443

server:
  enabled: false

connectInject:
  transparentProxy:
    defaultEnabled: true
  enabled: true
  default: true
  consulNode:
    meta:
      terraform-module: "hcp-eks-client"
