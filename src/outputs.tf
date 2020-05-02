# Kubernetes masters
output "kubernetes_masters_ip" {
  value = {
    for master in libvirt_domain.kubernetes_master:
    master.name => master.network_interface.0.addresses
  }
}

output "kubernetes_masters_fqdn" {
  value = {
    for master in libvirt_domain.kubernetes_master:
    master.name => master.network_interface.0.hostname
  }
}

output "kubernetes_masters_ssh" {
  value = {
    for master in libvirt_domain.kubernetes_master:
    master.name => format("ssh -i src/ssh/maintuser/id_rsa maintuser@%s",
      master.network_interface.0.hostname)
  }
}