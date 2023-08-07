#!/usr/bin/env bash
set -ex

start_service() {
  systemctl enable $1.service
  systemctl start $1.service
}

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
}

setup_consul() {
  echo "${consul_ca}" | base64 -d >/etc/consul.d/ca.pem
  echo "${consul_config}" | base64 -d >client.temp.1
  ip=$(hostname -I | awk '{print $1}')
  jq --arg token "${consul_acl_token}" '.acl += {"tokens":{"agent":"\($token)","default":"\($token)","initial_management":"\($token)"}}' client.temp.1 >client.temp.2
  jq '.ports = {"grpc":8502}' client.temp.2 >client.temp.3
  jq '.tls.defaults.ca_file = "/etc/consul.d/ca.pem"' client.temp.3 >client.temp.4
  jq '.bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"'${vpc_cidr}'\" | attr \"address\" }}"' client.temp.4 >/etc/consul.d/client.json
}

cd /home/ubuntu/

setup_networking
setup_deps

setup_consul

start_service "consul"

# nomad and consul service is type simple and might not be up and running just yet.
# sleep 10

echo "done"
