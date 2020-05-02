libvirt = {
  network   = "k8s"
  pool      = "kubernetes"
  pool_path = "/var/lib/libvirt/storage/kubernetes"
}

dns = {
  domain = "k8s.libvirt.local"
}

kubernetes_cluster = {
  num_masters = 3
  num_workers = 1
}
