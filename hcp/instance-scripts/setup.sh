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
  hostnamectl set-hostname "${hostname}"
}

setup_nginx_service() {
  cat >/etc/consul.d/service-nginx.json <<EOF
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
  chown consul:consul /etc/consul.d/service-nginx.json
}

setup_consul() {
  echo "${consul_ca}" | base64 -d >/etc/consul.d/ca.pem
  echo "${consul_config}" | base64 -d >client.temp.1
  jq '.tls.defaults.ca_file = "/etc/consul.d/ca.pem"' client.temp.1 >client.temp.2
  jq '.acl.tokens.agent = "'${consul_acl_token}'"' client.temp.2 > client.temp.3
  jq '.acl.tokens.default = "'${consul_acl_token}'"' client.temp.3 > client.temp.4
  jq '.bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"'${vpc_cidr}'\" | attr \"address\" }}"' client.temp.4 >/etc/consul.d/client.json
  rm /home/ubuntu/client.temp.*
  sed -i 's/notify/simple/g' /usr/lib/systemd/system/consul.service
  systemctl daemon-reload
  systemctl enable consul.service
  systemctl start consul.service
}

setup_cts() {
  useradd --system --home /etc/consul-nia.d --shell /bin/false consul-nia
  mkdir -p /opt/consul-nia && mkdir -p /etc/consul-nia.d
  touch /etc/consul-nia.d/consul-nia.env

  [[ ! -z "${cts_config}" ]] && cat << 'EOF' >/etc/systemd/system/cts.service
[Unit]
Description="HashiCorp Consul-Terraform-Sync - A Network Infrastructure Automation solution"
Documentation=https://www.consul.io/docs/nia
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul-nia.d/cts-config.hcl

[Service]
EnvironmentFile=/etc/consul-nia.d/consul-nia.env
User=consul-nia
Group=consul-nia
ExecStart=/usr/bin/consul-terraform-sync start -config-dir=/etc/consul-nia.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable cts.service

  [[ ! -z "${cts_config}" ]] && echo "${cts_config}" | base64 -d >/etc/consul-nia.d/cts-config.hcl
  [[ ! -z "${cts_variables}" ]] && echo "${cts_variables}" | base64 -d >/opt/consul-nia/cts-jumphost-module.tfvars
  [[ ! -z "${cts_policy}" ]] && echo "${cts_policy}" | base64 -d >/opt/consul-nia/cts-policy.hcl
  [[ ! -z "${cts_jumphost_module_zip}" ]] && echo "${cts_jumphost_module_zip}" | base64 -d >/opt/consul-nia/cts-jumphost-module.zip; unzip /opt/consul-nia/cts-jumphost-module.zip -d /opt/consul-nia/; rm /opt/consul-nia/cts-jumphost-module.zip
  chown --recursive consul-nia:consul-nia /opt/consul-nia && \
  chmod -R 0770 /opt/consul-nia && \
  chown --recursive consul-nia:consul-nia /etc/consul-nia.d && \
  chmod -R 0770 /etc/consul-nia.d
  usermod -a -G consul,consul-nia ubuntu
}

cd /home/ubuntu/

setup_networking
setup_deps
[[ -z "${cts_config}" ]] && setup_nginx_service
setup_consul
[[ ! -z "${cts_config}" ]] && setup_cts

echo "done"
