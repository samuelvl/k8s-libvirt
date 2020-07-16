resource "libvirt_network" "kubernetes" {
  name      = var.network.name
  domain    = var.dns.internal_zone.domain
  mode      = "nat"
  bridge    = "kubevirbr0"
  mtu       = 1500
  addresses = [ var.network.subnet ]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true

    hosts  {
      hostname = format("api.%s", var.dns.internal_zone.domain)
      ip       = local.load_balancer.ip
    }
  }

  # xml {
  #   xslt = file(format("%s/xslt/network-zone.xml", path.module))
  # }

  depends_on = [
    local_file.kubernetes_dnsmasq
  ]
}
