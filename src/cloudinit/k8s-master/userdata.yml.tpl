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
packages:
  - qemu-guest-agent
write_files:
  # Etcd configuration
  - path: /etc/etcd/certificates/etcd-root-ca.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${etcd_root_ca}
  - path: /etc/etcd/certificates/etcd-member.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${etcd_member_certificate}
  - path: /etc/etcd/certificates/etcd-member.key
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${etcd_member_private_key}
  - path: /etc/systemd/system/etcd.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=etcd
      Documentation=https://github.com/etcd-io/etcd
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=notify
      ExecStart=/usr/local/bin/etcd \
        --name ${etcd_member_name} \
        --cert-file=/etc/etcd/certificates/etcd-member.pem \
        --key-file=/etc/etcd/certificates/etcd-member.key \
        --peer-cert-file=/etc/etcd/certificates/etcd-member.pem \
        --peer-key-file=/etc/etcd/certificates/etcd-member.key \
        --trusted-ca-file=/etc/etcd/certificates/etcd-root-ca.pem \
        --peer-trusted-ca-file=/etc/etcd/certificates/etcd-root-ca.pem \
        --peer-client-cert-auth \
        --client-cert-auth \
        --initial-advertise-peer-urls https://${etcd_member_ip}:2380 \
        --listen-peer-urls https://${etcd_member_ip}:2380 \
        --listen-client-urls https://${etcd_member_ip}:2379,https://127.0.0.1:2379 \
        --advertise-client-urls https://${etcd_member_ip}:2379 \
        --initial-cluster-token etcd-cluster-0 \
        --initial-cluster ${etcd_initial_cluster} \
        --initial-cluster-state new \
        --data-dir=/var/lib/etcd
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # Kubernetes API Server configuration
  - path: /etc/kubernetes/certificates/kube-root-ca.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${kube_root_ca_certificate}
  - path: /etc/kubernetes/certificates/kube-root-ca.key
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kube_root_ca_private_key}
  - path: /etc/kubernetes/certificates/kube-api-server.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${kube_api_server_certificate}
  - path: /etc/kubernetes/certificates/kube-api-server.key
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kube_api_server_private_key}
  - path: /etc/kubernetes/certificates/kube-service-accounts.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${kube_service_accounts_certificate}
  - path: /etc/kubernetes/certificates/kube-service-accounts.key
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kube_service_accounts_private_key}
  - path: /etc/kubernetes/manifests/encryption-config.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${etcd_encryption_config}

  # Kubernetes controller manager configuration
  - path: /etc/kubernetes/auth/kubeconfig-kube-controller-manager.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubeconfig_kube_controller_manager}

  # Kubernetes scheduler configuration
  - path: /etc/kubernetes/auth/kubeconfig-kube-scheduler.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubeconfig_kube_scheduler}

# Every boot
bootcmd:
  - [ sh, -c, 'echo $(date) | sudo tee -a /root/bootcmd.log' ]

# Run once for setup
runcmd:
  - [ sh, -c, 'echo $(date) | sudo tee -a /root/runcmd.log' ]
  - [ mkdir, -p, /var/lib/etcd ]
  - [ curl, -L, "https://storage.googleapis.com/etcd/v${etcd_version}/etcd-v${etcd_version}-linux-amd64.tar.gz", -o, /tmp/etcd.tar.gz ]
  - [ tar, -xzvf, /tmp/etcd.tar.gz, -C, /usr/local/bin, --strip-components=1 ]
  - [ ln, -s, /usr/local/bin/etcdctl, /usr/local/sbin/etcdctl ]
  - [ rm, -f, /tmp/etcd.tar.gz ]
  - [ systemctl, enable, etcd.service ]
  - [ systemctl, start, etcd.service ]

# Written to /var/log/cloud-init-output.log
final_message: "The system is finall up, after $UPTIME seconds"
