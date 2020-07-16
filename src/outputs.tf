# Load balancer
output "kubernetes_load_balancer" {
  value = {
    fqdn    = local.load_balancer.fqdn
    ip      = local.load_balancer.ip
    ssh     = formatlist("ssh -i src/ssh/maintuser/id_rsa maintuser@%s", local.load_balancer.fqdn)
    metrics =  format("http://%s:5555/haproxy?stats", local.load_balancer.fqdn)
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
    fqdn = local.kubernetes_masters.*.fqdn
    ip   = local.kubernetes_masters.*.ip
    ssh  = formatlist("ssh -i src/ssh/maintuser/id_rsa maintuser@%s", local.kubernetes_masters.*.fqdn)
  }
}

# Kubernetes workers
output "kubernetes_workers" {
  value = {
    fqdn       = local.kubernetes_workers.*.fqdn
    ip_address = local.kubernetes_workers.*.ip
    ssh        = formatlist("ssh -i src/ssh/maintuser/id_rsa maintuser@%s", local.kubernetes_workers.*.fqdn)
  }
}
