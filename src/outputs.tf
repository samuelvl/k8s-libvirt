# Load balancer
output "kubernetes_load_balancer" {
  value = {
    fqdn       = libvirt_domain.load_balancer.network_interface.0.hostname
    ip_address = libvirt_domain.load_balancer.network_interface.0.addresses.0
    ssh        = format("ssh -i src/ssh/maintuser/id_rsa maintuser@%s",
      libvirt_domain.load_balancer.network_interface.0.hostname)
    metrics   =  format("http://%s:5555/haproxy?stats",
      libvirt_domain.load_balancer.network_interface.0.hostname)
  }
}

# Kubernetes cluster
output "kubernetes_cluster" {
  value = {
    api_server = format("https://api.%s:6443", var.dns.internal_zone.domain)
  }
}

# Kubernetes masters
output "kubernetes_masters" {
  value = {
    fqdn       = libvirt_domain.kubernetes_master.*.network_interface.0.hostname
    ip_address = libvirt_domain.kubernetes_master.*.network_interface.0.addresses.0
    ssh        = formatlist("ssh -i src/ssh/maintuser/id_rsa maintuser@%s",
      libvirt_domain.kubernetes_master.*.network_interface.0.hostname)
  }
}

# Kubernetes workers
output "kubernetes_workers" {
  value = {
    fqdn       = libvirt_domain.kubernetes_worker.*.network_interface.0.hostname
    ip_address = libvirt_domain.kubernetes_worker.*.network_interface.0.addresses.0
    ssh        = formatlist("ssh -i src/ssh/maintuser/id_rsa maintuser@%s",
      libvirt_domain.kubernetes_worker.*.network_interface.0.hostname)
  }
}