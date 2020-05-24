data "template_file" "kubernetes_dns_svc" {

  template = file(format("%s/dns/coredns/svc.yml.tpl", path.module))

  vars = {
    kube_dns_server = var.kubernetes_cluster.dns_server
  }
}

resource "local_file" "kubernetes_dns_svc" {
  filename             = format("%s/dns/coredns/svc.yml", path.module)
  content              = data.template_file.kubernetes_dns_svc.rendered
  file_permission      = "0644"
  directory_permission = "0755"
}