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
    server = "10.2.0.1"
  }
  internal_zone = {
    domain = "k8s.libvirt.int"
    server = "10.1.0.1"
  }
}

kubernetes_inventory = {
  "master00" = {
    ip_address  = "10.1.0.10"
    mac_address = "AA:00:00:00:00:00"
  },
  "master01" = {
    ip_address  = "10.1.0.11"
    mac_address = "AA:00:00:00:00:01"
  },
  "master02" = {
    ip_address  = "10.1.0.12"
    mac_address = "AA:00:00:00:00:02"
  },
  "worker00" = {
    ip_address  = "10.1.0.100"
    mac_address = "EE:00:00:00:00:01"
  },
}

kubernetes_cluster = {
  num_masters  = 3
  num_workers  = 1

  etcd_version = "3.4.7"

  svc_network  = {
    cidr    = "172.0.0.0/16",
    gateway = "172.0.0.1",
  }

  pod_network  = {
    cidr    = "172.255.0.0/16",
    gateway = "172.255.0.1",
  }
}
