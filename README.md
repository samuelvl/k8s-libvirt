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

### DNS

If dns is enabled in a libvirt network, it will use `dnsmasq` to setup a DNS server listening in the port 53 of the network interface (e.g. virbr100). This DNS will handle A records for virtual machines but can also be used for creating additional A, PTR, SRV and TXT records.

Configure NetworkManager to also use `dnamsq` to setup a DNS server to resolve all local requests. Edit the file `/etc/NetworkManager/conf.d/localdns.conf` and add the following configuration.

```bash
[main]
dns=dnsmasq
```

Configure the NetworkManager DNS server to forward requests with destination the libvirt domains, to corresponding DNS servers. Edit the file `/etc/NetworkManager/dnsmasq.d/libvirt_dnsmasq.conf` and add the following configuration (use your network interface gateway).

```bash
server=/k8s.libvirt.com/10.1.0.1
server=/k8s.libvirt.local/172.1.0.1
```

Restart NetworkManager service.

```bash
systemctl restart NetworkManager
```

## References

- https://github.com/kelseyhightower/kubernetes-the-hard-way