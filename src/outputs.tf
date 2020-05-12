# Load balancer
output "load_balancers_info" {
  value = libvirt_domain.load_balancer.network_interface.0.addresses
}

output "load_balancer_fqdn" {
  value = libvirt_domain.load_balancer.network_interface.0.hostname
}

output "load_balancer_ssh" {
  value = format("ssh -i src/ssh/maintuser/id_rsa maintuser@%s",
      libvirt_domain.load_balancer.network_interface.0.hostname)
}

# Kubernetes masters
output "kubernetes_masters_info" {
  value = {
    for master in libvirt_domain.kubernetes_master:
    master.network_interface.0.hostname => master.network_interface.0.addresses
  }
}

output "kubernetes_masters_ssh" {
  value = {
    for master in libvirt_domain.kubernetes_master:
    master.name => format("ssh -i src/ssh/maintuser/id_rsa maintuser@%s",
      master.network_interface.0.hostname)
  }
}

# Kubernetes workers
output "kubernetes_workers_info" {
  value = {
    for worker in libvirt_domain.kubernetes_worker:
    worker.network_interface.0.hostname => worker.network_interface.0.addresses
  }
}

output "kubernetes_workers_ssh" {
  value = {
    for worker in libvirt_domain.kubernetes_worker:
    worker.name => format("ssh -i src/ssh/maintuser/id_rsa maintuser@%s",
      worker.network_interface.0.hostname)
  }
}