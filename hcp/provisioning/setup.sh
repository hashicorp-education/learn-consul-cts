#!/usr/bin/env bash
set -ex

setup_deps() {
  add-apt-repository universe -y
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
  apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
  apt update -qy
  version="${consul_version}"
  consul_package="consul="$${version:1}"*"
  cts_package="consul-terraform-sync="$${cts_version:1}"*"
  apt install -qy apt-transport-https gnupg2 curl lsb-release $${consul_package} $${cts_package} unzip jq tree apache2-utils nginx awscli
}

setup_networking() {
  # echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-arptables
  # echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-ip6tables
  # echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-iptables
  curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
  mkdir -p /opt/cni/bin
  tar -C /opt/cni/bin -xzf cni-plugins.tgz
  rm /home/ubuntu/cni-plugins.tgz
}

setup_consul() {
  echo "${consul_ca}" | base64 -d >/etc/consul.d/ca.pem
  echo "${consul_config}" | base64 -d >client.temp.1
  jq '.tls.defaults.ca_file = "/etc/consul.d/ca.pem"' client.temp.1 >client.temp.2
  jq '.acl.tokens.agent = "'${consul_acl_token}'"' client.temp.2 > client.temp.3
  jq '.acl.tokens.default = "'${consul_acl_token}'"' client.temp.3 > client.temp.4
  jq '.bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"'${vpc_cidr}'\" | attr \"address\" }}"' client.temp.4 >/etc/consul.d/client.json
  rm /home/ubuntu/client.temp.*
  [[ ! -z "${cts_config}" ]] && echo "${cts_config}" | base64 -d >cts/cts-config.hcl
  sed -i 's/notify/simple/g' /usr/lib/systemd/system/consul.service
  systemctl daemon-reload
  systemctl enable consul.service
  systemctl start consul.service
}

setup_nginx_service_consul() {
  cat <<EOF >/etc/consul.d/service-nginx.json
{
  "service": {
      "name": "nginx",
      "port": 80,
      "check": {
          "id": "nginx",
          "name": "NGINX TCP on port 80",
          "tcp": "localhost:80",
          "interval": "10s",
          "timeout": "1s"
      }
  }
}
EOF
  chown -R consul:consul /etc/consul.d/*
}

cd /home/ubuntu/

setup_networking
setup_deps
setup_consul
[[ -z "${cts_config}" ]] && setup_nginx_service_consul # set up example nginx if instance is not the CTS one

echo "done"
