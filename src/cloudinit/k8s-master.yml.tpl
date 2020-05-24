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
  - path: /etc/kubernetes/certificates/kube-apiserver.pem
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${kube_api_server_certificate}
  - path: /etc/kubernetes/certificates/kube-apiserver.key
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
  - path: /etc/kubernetes/config/encryption-config.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${etcd_encryption_config}
  - path: /etc/systemd/system/kube-apiserver.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Kubernetes API Server
      Documentation=https://github.com/kubernetes/kubernetes

      [Service]
      ExecStart=/usr/local/bin/kube-apiserver \
        --v=2 \
        --bind-address=0.0.0.0 \
        --advertise-address=${ip_address} \
        --apiserver-count=3 \
        --client-ca-file=/etc/kubernetes/certificates/kube-root-ca.pem \
        --tls-cert-file=/etc/kubernetes/certificates/kube-apiserver.pem \
        --tls-private-key-file=/etc/kubernetes/certificates/kube-apiserver.key \
        --allow-privileged=true \
        --etcd-cafile=/etc/etcd/certificates/etcd-root-ca.pem \
        --etcd-certfile=/etc/etcd/certificates/etcd-member.pem \
        --etcd-keyfile=/etc/etcd/certificates/etcd-member.key \
        --etcd-servers=${etcd_servers} \
        --kubelet-https=true \
        --kubelet-certificate-authority=/etc/kubernetes/certificates/kube-root-ca.pem \
        --kubelet-client-certificate=/etc/kubernetes/certificates/kube-apiserver.pem \
        --kubelet-client-key=/etc/kubernetes/certificates/kube-apiserver.key \
        --runtime-config="api/all=true" \
        --service-cluster-ip-range=${kube_svc_network_cidr} \
        --service-node-port-range=${kube_nodeport_range} \
        --service-account-key-file=/etc/kubernetes/certificates/kube-service-accounts.key \
        --encryption-provider-config=/etc/kubernetes/config/encryption-config.yml \
        --authorization-mode=Node,RBAC \
        --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
        --event-ttl=1h \
        --audit-log-maxage=30 \
        --audit-log-maxbackup=3 \
        --audit-log-maxsize=100 \
        --audit-log-path=/var/log/audit.log
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # Kubernetes controller manager configuration
  - path: /etc/kubernetes/auth/kubeconfig-kube-controller-manager.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubeconfig_kube_controller_manager}
  - path: /etc/systemd/system/kube-controller-manager.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Kubernetes Controller Manager
      Documentation=https://github.com/kubernetes/kubernetes

      [Service]
      ExecStart=/usr/local/bin/kube-controller-manager \
        --v=2 \
        --address=0.0.0.0 \
        --leader-elect=true \
        --cluster-name=kubernetes \
        --cluster-cidr=${kube_pod_network_cidr} \
        --allocate-node-cidrs=true \
        --root-ca-file=/etc/kubernetes/certificates/kube-root-ca.pem \
        --cluster-signing-cert-file=/etc/kubernetes/certificates/kube-root-ca.pem \
        --cluster-signing-key-file=/etc/kubernetes/certificates/kube-root-ca.key \
        --service-cluster-ip-range=${kube_svc_network_cidr} \
        --use-service-account-credentials=true \
        --kubeconfig=/etc/kubernetes/auth/kubeconfig-kube-controller-manager.yml \
        --service-account-private-key-file=/etc/kubernetes/certificates/kube-service-accounts.key
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # Kubernetes scheduler configuration
  - path: /etc/kubernetes/auth/kubeconfig-kube-scheduler.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubeconfig_kube_scheduler}
  - path: /etc/kubernetes/config/kube-scheduler.yml
    owner: root:root
    permissions: "0644"
    content: |
      apiVersion: kubescheduler.config.k8s.io/v1alpha1
      kind: KubeSchedulerConfiguration
      clientConnection:
        kubeconfig: "/etc/kubernetes/auth/kubeconfig-kube-scheduler.yml"
      leaderElection:
        leaderElect: true
  - path: /etc/systemd/system/kube-scheduler.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Kubernetes Scheduler
      Documentation=https://github.com/kubernetes/kubernetes

      [Service]
      ExecStart=/usr/local/bin/kube-scheduler \
        --v=2 \
        --config=/etc/kubernetes/config/kube-scheduler.yml
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # Kubernetes configuration manifests
  - path: /etc/kubernetes/auth/kubeconfig-admin.yml
    owner: root:root
    permissions: "0640"
    encoding: b64
    content: ${kubeconfig_admin}
  - path: /etc/kubernetes/manifests/cluster-rbac.yml
    owner: root:root
    permissions: "0644"
    content: |
      ---
      apiVersion: rbac.authorization.k8s.io/v1beta1
      kind: ClusterRole
      metadata:
        name: system:kube-apiserver-to-kubelet
        annotations:
          rbac.authorization.kubernetes.io/autoupdate: "true"
        labels:
          kubernetes.io/bootstrapping: rbac-defaults
      rules:
        - apiGroups:
            - ""
          resources:
            - nodes/proxy
            - nodes/stats
            - nodes/log
            - nodes/spec
            - nodes/metrics
          verbs:
            - "*"

      ---
      apiVersion: rbac.authorization.k8s.io/v1beta1
      kind: ClusterRoleBinding
      metadata:
        name: system:kube-apiserver
        namespace: ""
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: ClusterRole
        name: system:kube-apiserver-to-kubelet
      subjects:
        - apiGroup: rbac.authorization.k8s.io
          kind: User
          name: Kubernetes

# Every boot
bootcmd:
  - [ sh, -c, 'echo $(date) | sudo tee -a /root/bootcmd.log' ]

# Run once for setup
runcmd:
  - [ sh, -c, 'echo $(date) | sudo tee -a /root/runcmd.log' ]
  # Apply custom kernel parameters
  - [ sysctl, --system ]
  # Download and start the etcd cluster
  - [ mkdir, -p, /var/lib/etcd ]
  - [ curl, -L, "https://storage.googleapis.com/etcd/v${etcd_version}/etcd-v${etcd_version}-linux-amd64.tar.gz", -o, /tmp/etcd.tar.gz ]
  - [ tar, -xzvf, /tmp/etcd.tar.gz, -C, /usr/local/bin, --strip-components=1 ]
  - [ ln, -s, /usr/local/bin/etcdctl, /usr/local/sbin/etcdctl ]
  - [ rm, -f, /tmp/etcd.tar.gz ]
  - [ systemctl, enable, etcd.service ]
  - [ systemctl, start, etcd.service ]
  # Download the API server
  - [ curl, -L, "https://storage.googleapis.com/kubernetes-release/release/v${kube_version}/bin/linux/amd64/kube-apiserver", -o, /usr/local/bin/kube-apiserver ]
  - [ chmod, +x, /usr/local/bin/kube-apiserver ]
  # Download the controller manager
  - [ curl, -L, "https://storage.googleapis.com/kubernetes-release/release/v${kube_version}/bin/linux/amd64/kube-controller-manager", -o, /usr/local/bin/kube-controller-manager ]
  - [ chmod, +x, /usr/local/bin/kube-controller-manager ]
  # Download the kube scheduler
  - [ curl, -L, "https://storage.googleapis.com/kubernetes-release/release/v${kube_version}/bin/linux/amd64/kube-scheduler", -o, /usr/local/bin/kube-scheduler ]
  - [ chmod, +x, /usr/local/bin/kube-scheduler ]
  # Download kubectl client
  - [ curl, -L, "https://storage.googleapis.com/kubernetes-release/release/v${kube_version}/bin/linux/amd64/kubectl", -o, /usr/local/bin/kubectl ]
  - [ chmod, +x, /usr/local/bin/kubectl ]
  - [ ln, -s, /usr/local/bin/kubectl, /usr/local/sbin/kubectl ]
  # Start the Kubernetes control plane
  - [ systemctl, enable, kube-apiserver.service, kube-controller-manager.service, kube-scheduler.service ]
  - [ systemctl, start, kube-apiserver.service, kube-controller-manager.service, kube-scheduler.service ]
  # Configure Kubernetes cluster
  - [ kubectl, apply, -f, /etc/kubernetes/manifests, --kubeconfig, /etc/kubernetes/auth/kubeconfig-admin.yml ]

# Written to /var/log/cloud-init-output.log
final_message: "The system is finall up, after $UPTIME seconds"
