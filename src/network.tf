resource "libvirt_network" "kubernetes_public" {
  name      = var.libvirt.network_public
  domain    = var.dns.public_zone.domain
  mode      = "route"
  bridge    = "kubevirbr0"
  mtu       = 1500
  addresses = [ "10.1.0.0/24" ]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true

    forwarders {
      domain  = var.dns.internal_zone.domain
      address = "172.1.0.1"
    }
  }

  xml {
    xslt = file(format("%s/xslt/network-public.xml", path.module))
  }
}

resource "libvirt_network" "kubernetes_internal" {
  name      = var.libvirt.network_internal
  domain    = var.dns.internal_zone.domain
  mode      = "route"
  bridge    = "kubevirbr1"
  mtu       = 1500
  addresses = [ "172.1.0.0/24" ]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true

    forwarders {
      domain  = var.dns.public_zone.domain
      address = "10.1.0.1"
    }
  }

  xml {
    xslt = file(format("%s/xslt/network-internal.xml", path.module))
  }
}