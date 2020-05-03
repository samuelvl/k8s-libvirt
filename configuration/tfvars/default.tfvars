load_balancer = {
  hostname = "lb"
  base_img = "/var/lib/libvirt/images/fedora-coreos-31.20200310.3.0-qemu.x86_64.qcow2"
  vcpu     = 1
  memory   = 512
}

kubernetes_master = {
  hostname = "master"
  base_img = "https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.1.1911-20200113.3.x86_64.qcow2"
  vcpu     = 2
  memory   = 2048
}

kubernetes_worker = {
  hostname = "worker"
  base_img = "https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.1.1911-20200113.3.x86_64.qcow2"
  vcpu     = 1
  memory   = 1024
}