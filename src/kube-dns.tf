data "template_file" "kubernetes_dns_helm" {

  template = file(format("%s/dns/coredns/values.yaml.tpl", path.module))

  vars = {
    kube_dns_server = var.kubernetes_cluster.dns_server
  }
}

resource "local_file" "kubernetes_dns_helm" {
  filename             = format("%s/dns/coredns/values.yaml", path.module)
  content              = data.template_file.kubernetes_dns_helm.rendered
  file_permission      = "0644"
  directory_permission = "0755"
}
