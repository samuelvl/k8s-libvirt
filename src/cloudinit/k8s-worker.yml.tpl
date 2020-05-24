#cloud-config
hostname: ${hostname}
fqdn: ${fqdn}
manage_etc_hosts: true
ssh_pwauth: false
disable_root: false
users:
  - name: maintuser
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups:
      - sudo
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - ${ssh_pubkey}
yum_repos:
  CentOS-openSUSE-libcontainers-stable:
    name: Stable Releases of Upstream github.com/containers packages (CentOS_8)
    type: rpm-md
    enabled: true
    baseurl: https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/
    gpgcheck: true
    gpgkey: https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/repodata/repomd.xml.key
  CentOS-openSUSE-crio-testing:
    name: Last release available in ${crio_version} branch (CentOS_8)
    type: rpm-md
    enabled: true
    baseurl: http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${crio_version}/CentOS_8/
    gpgcheck: true
    gpgkey: http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${crio_version}/CentOS_8/repodata/repomd.xml.key
packages:
  - qemu-guest-agent
  - iptables
  - socat
  - conntrack
  - ipset
  - cri-o

write_files:
  # Networking configuration
  - path: /etc/sysctl.d/99-enable-ip-forwarding.conf
    owner: root:root
    permissions: "0644"
    content: |
      # IPv4
      net.ipv4.ip_forward = 1
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-arptables = 1
      # IPv6
      net.ipv6.conf.all.forwarding = 1
      net.bridge.bridge-nf-call-ip6tables = 1
  - path: /etc/modules-load.d/br_netfilter.conf
    owner: root:root
    permissions: "0644"
    content: |
      br_netfilter
  # CRI-O configuration
  - path: /etc/cni/net.d/100-crio-bridge.conf
    owner: root:root
    permissions: "0644"
    content: |
      {
          "cniVersion": "0.3.1",
          "name": "crio",
          "type": "bridge",
          "bridge": "cni0",
          "isGateway": true,
          "ipMasq": true,
          "hairpinMode": true,
          "ipam": {
              "type": "host-local",
              "routes": [
                  { "dst": "0.0.0.0/0" }
              ],
              "ranges": [
                  [{ "subnet": "${kube_hostpod_network_cidr}" }]
              ]
          }
      }
  # Kubelet configuration
  - path: /etc/kubernetes/certificates/kube-root-ca.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${kube_root_ca_certificate}
  - path: /etc/kubernetes/certificates/kubelet.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${kubelet_certificate}
  - path: /etc/kubernetes/certificates/kubelet.key
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubelet_private_key}
  - path: /etc/kubernetes/auth/kubeconfig-kubelet.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubeconfig_kubelet}
  - path: /etc/kubernetes/config/kubelet.yml
    owner: root:root
    permissions: "0644"
    content: |
      apiVersion: kubelet.config.k8s.io/v1beta1
      kind: KubeletConfiguration
      clusterDomain: cluster.local
      clusterDNS:
        - ${kube_dns_server}
      podCIDR: ${kube_hostpod_network_cidr}
      cgroupDriver: systemd
      resolvConf: /etc/resolv.conf
      authentication:
        anonymous:
          enabled: false
        webhook:
          enabled: true
        x509:
          clientCAFile: /etc/kubernetes/certificates/kube-root-ca.pem
      tlsCertFile: /etc/kubernetes/certificates/kubelet.pem
      tlsPrivateKeyFile: /etc/kubernetes/certificates/kubelet.key
      authorization:
        mode: Webhook
      runtimeRequestTimeout: 15m
  - path: /etc/systemd/system/kubelet.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Kubernetes Kubelet
      Documentation=https://github.com/kubernetes/kubernetes
      After=crio.service
      Requires=crio.service

      [Service]
      ExecStart=/usr/local/bin/kubelet \
        --v=2 \
        --hostname-override=${hostname} \
        --config=/etc/kubernetes/config/kubelet.yml \
        --kubeconfig=/etc/kubernetes/auth/kubeconfig-kubelet.yml \
        --container-runtime=remote \
        --container-runtime-endpoint=/var/run/crio/crio.sock \
        --node-labels=node.kubernetes.io/worker \
        --image-pull-progress-deadline=2m \
        --network-plugin=cni \
        --register-node=true
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
  # Kubernetes proxy configuration
  - path: /etc/kubernetes/auth/kubeconfig-kube-proxy.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubeconfig_kube_proxy}
  - path: /etc/kubernetes/config/kube-proxy.yml
    owner: root:root
    permissions: "0644"
    content: |
      kind: KubeProxyConfiguration
      apiVersion: kubeproxy.config.k8s.io/v1alpha1
      mode: iptables
      clusterCIDR: ${kube_pod_network_cidr}
      clientConnection:
        kubeconfig: /etc/kubernetes/auth/kubeconfig-kube-proxy.yml
  - path: /etc/systemd/system/kube-proxy.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Kubernetes Proxy
      Documentation=https://github.com/kubernetes/kubernetes

      [Service]
      ExecStart=/usr/local/bin/kube-proxy \
        --config=/etc/kubernetes/config/kube-proxy.yml
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

# every boot
bootcmd:
  - [ sh, -c, 'echo $(date) | sudo tee -a /root/bootcmd.log' ]

# run once for setup
runcmd:
  - [ sh, -c, 'echo $(date) | sudo tee -a /root/runcmd.log' ]
  # Apply custom kernel parameters
  - [ sysctl, --system ]
  # Load kernel modules
  - [ systemctl, restart, systemd-modules-load ]
  # Download crictl tool
  - [ curl, -L, -o, /tmp/crictl.tar.gz, "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${crio_version}.0/crictl-v${crio_version}.0-linux-amd64.tar.gz" ]
  - [ tar, -xzvf, /tmp/crictl.tar.gz, -C, /usr/local/bin ]
  - [ ln, -s, /usr/local/bin/crictl, /usr/local/sbin/crictl ]
  - [ rm, -f, /tmp/crictl.tar.gz ]
  # Configure and start CRI-O runtime
  - [ ln, -s, /usr/bin/conmon, /usr/libexec/crio/conmon ] # BUG: 14052020 (path not found)
  - [ systemctl, enable, crio.service ]
  - [ systemctl, start, crio.service ]
  # Download kubelet
  - [ curl, -L, -o, /usr/local/bin/kubelet, "https://storage.googleapis.com/kubernetes-release/release/v${kube_version}/bin/linux/amd64/kubelet" ]
  - [ chmod, +x, /usr/local/bin/kubelet ]
  # Download kube-proxy
  - [ curl, -L, -o, /usr/local/bin/kube-proxy, "https://storage.googleapis.com/kubernetes-release/release/v${kube_version}/bin/linux/amd64/kube-proxy" ]
  - [ chmod, +x, /usr/local/bin/kube-proxy ]
  # Start Kubernetes compute controllers
  - [ systemctl, enable, kubelet.service, kube-proxy.service ]
  - [ systemctl, start, kubelet.service, kube-proxy.service ]

# written to /var/log/cloud-init-output.log
final_message: "The system is finall up, after $UPTIME seconds"
