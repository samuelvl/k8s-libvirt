# Kubernetes

Deploy a Kubernetes cluster on libvirt using Terraform.

## Requirements

- Libvirt (tested with 5.6.0 version).
- Terraform (tested with 0.12.24 version).
- Libvirt provider for Terraform (tested with 0.6.2 version).

Install requirements.

```bash
make requirements
```

## Setup Libvirt

Use `virsh` command utility to configure libvirt.

```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

Check if libvirt is running.

```bash
virsh version --daemon
```

### QEMU permissions

The provider does not currently support to create volumes with different mode than `root:root` so QEMU agent must run as priviledged. Set user and password in `/etc/libvirt/qemu.conf` file.

```bash
...
user = "root"
group = "root"
...
```

Restart libvirt daemon.

```bash
systemctl restart libvirtd
```

## CA

Copy the following files to the masters.

```bash
src/ca
├── clients
│   ├── api-server
│   │   ├── master00
│   │   │   ├── certificate.crt
│   │   │   └── certificate.key
│   │   ├── master01
│   │   │   ├── certificate.crt
│   │   │   └── certificate.key
│   │   └── master02
│   │       ├── certificate.crt
│   │       └── certificate.key
│   └── service-account
│       ├── certificate.crt
│       └── certificate.key
└── root-ca
    ├── certificate.crt
    └── certificate.key
```

Copy the following files to the workers.

```bash
src/ca
├── clients
│   └── kubelet
│       └── worker00
│           ├── certificate.crt
│           └── certificate.key
└── root-ca
    └── certificate.crt
```

## Kubeconfig

Create a new kubeconfig for worker.

```bash
kubectl config set-cluster kubernetes \
    --server=https://api.k8s.libvirt.int:6443 \
    --certificate-authority=src/ca/root-ca/certificate.pem \
    --embed-certs=true \
    --kubeconfig=worker00.kubeconfig
```

Add TLS authentication to the kubeconfig.

```bash
kubectl config set-credentials system:node:worker00 \
    --client-certificate=src/ca/clients/kubelet/worker00/certificate.pem \
    --client-key=src/ca/clients/kubelet/worker00/certificate.key \
    --embed-certs=true \
    --kubeconfig=worker00.kubeconfig
```

Create default context.

```bash
kubectl config set-context default \
    --cluster=kubernetes \
    --user=system:node:worker00 \
    --kubeconfig=worker00.kubeconfig
```

Use the default context by default.

```bash
kubectl config use-context default --kubeconfig=worker00.kubeconfig
```

## ETCD

```bash
ETCD_VER=v3.4.7

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

curl -L https://storage.googleapis.com/etcd/v3.4.7/etcd-v3.4.7-linux-amd64.tar.gz -o /tmp/etcd-tools.tar.gz
tar xzvf /tmp/etcd-tools.tar.gz -C /usr/local/bin --strip-components=1 etcd-v3.4.7-linux-amd64/etcd etcd-v3.4.7-linux-amd64/etcdctl
ln -s /usr/local/bin/etcdctl /usr/local/sbin/etcdctl
rm -f /tmp/etcd-v3.4.7-linux-amd64.tar.gz
```

```bash
export ETCDCTL_CACERT="/etc/etcd/certificates/etcd-root-ca.pem"
export ETCDCTL_CERT="/etc/etcd/certificates/etcd-member.pem"
export ETCDCTL_KEY="/etc/etcd/certificates/etcd-member.key"

etcdctl member list -w table
etcdctl endpoint status --cluster=true -w table
```

## Troubleshooting

Enable debug mode by setting `TF_VAR_DEBUG` to `true` before planning terraform changes.

```bash
export TF_VAR_DEBUG="true"
```

## References

- https://github.com/kelseyhightower/kubernetes-the-hard-way