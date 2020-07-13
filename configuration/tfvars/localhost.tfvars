libvirt = {
  pool      = "kubernetes"
  pool_path = "storage/volumes/kubernetes"
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

kubernetes_cluster = {
  num_masters     = 3
  num_workers     = 1
  version         = "1.18.0"
  etcd_version    = "3.4.7"
  crio_version    = "1.18"
  node_port_range = "30000-32767"
  dns_server      = "172.0.0.100"

  svc_network  = {
    cidr    = "172.0.0.0/16",
    gateway = "172.0.0.1",
  }

  pod_network  = {
    cidr    = "172.255.0.0/16",
    gateway = "172.255.0.1",
  }
}

kubernetes_inventory = {
  "lb" = {
    ip_address  = "10.1.0.250"
    mac_address = "0A:00:00:00:00:00"
  }
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