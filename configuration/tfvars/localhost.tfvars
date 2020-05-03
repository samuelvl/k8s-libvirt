libvirt = {
  network_public   = "k8s-public"
  network_internal = "k8s-internal"
  pool             = "kubernetes"
  pool_path        = "/var/lib/libvirt/storage/kubernetes"
}

dns = {
  public_zone = {
    domain = "k8s.libvirt.com"
  }
  internal_zone = {
    domain = "k8s.libvirt.local"
  }
}

kubernetes_cluster = {
  num_masters = 3
  num_workers = 1
}