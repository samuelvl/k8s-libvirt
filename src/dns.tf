data "template_file" "kubernetes_dnsmasq" {

  template = file(format("%s/dns/kubernetes_dnsmasq.conf", path.module))

  vars = {
    dns_internal_zone   = var.dns.internal_zone.domain
    dns_internal_server = var.network.gateway
  }
}

resource "local_file" "nm_enable_dnsmasq" {
  filename             = "/etc/NetworkManager/conf.d/nm_enable_dnsmasq.conf"
  content              = file(format("%s/dns/nm_enable_dnsmasq.conf", path.module))
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "kubernetes_dnsmasq" {
  filename             = "/etc/NetworkManager/dnsmasq.d/kubernetes_dnsmasq.conf"
  content              = data.template_file.kubernetes_dnsmasq.rendered
  file_permission      = "0644"
  directory_permission = "0755"

  provisioner "local-exec" {
    command = "systemctl restart NetworkManager"
  }

  depends_on = [
    local_file.nm_enable_dnsmasq
  ]
}
