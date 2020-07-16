load_balancer = {
  id               = "lb"
  base_img         = "src/storage/images/fedora-coreos-32.20200629.3.0.x86_64.qcow2"
  vcpu             = 1
  memory           = 512
  ha_proxy_version = "2.0.14"
}

kubernetes_master = {
  id       = "master"
  hostname = "master"
  base_img = "src/storage/images/CentOS-8-GenericCloud-8.1.1911-20200113.3.x86_64.qcow2"
  vcpu     = 2
  memory   = 2048
}

kubernetes_worker = {
  id       = "worker"
  base_img = "src/storage/images/CentOS-8-GenericCloud-8.1.1911-20200113.3.x86_64.qcow2"
  vcpu     = 1
  memory   = 1024
}
