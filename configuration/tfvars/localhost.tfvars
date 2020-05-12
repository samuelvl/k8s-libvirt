libvirt = {
  pool      = "kubernetes"
  pool_path = "/var/lib/libvirt/storage/kubernetes"
}

network = {
  name    = "kubernetes"
  subnet  = "10.1.0.0/24"
  gateway = "10.1.0.1"
}

dns = {
  public_zone = {
    domain = "k8s.libvirt.pub"
  }
  internal_zone = {
    domain = "k8s.libvirt.int"
  }
}

kubernetes_cluster = {
  num_masters = 3
  num_workers = 1
  svc_network = {
    cidr    = "172.0.0.0/16",
    gateway = "172.0.0.1",
  }
  pod_network= {
    cidr    = "172.255.0.0/16",
    gateway = "172.255.0.1",
  }
}
