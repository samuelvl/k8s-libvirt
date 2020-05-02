resource "libvirt_network" "kubernetes" {
  name      = var.libvirt.network
  domain    = var.dns.domain
  mode      = "nat"
  bridge    = "kubevirbr0"
  mtu       = 1500
  addresses = [ "172.1.0.0/24" ]

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true

    forwarders {
      address = "80.80.80.80"
    }

    forwarders {
      address = "80.80.80.81"
    }
  }
}