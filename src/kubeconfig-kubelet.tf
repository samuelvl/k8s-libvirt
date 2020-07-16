data "template_file" "kubeconfig_kubelet" {

  count = var.kubernetes_cluster.num_workers

  template = file(format("%s/kubeconfig/base.yml.tpl", path.module))

  vars = {
    kube_cluster_id                = "libvirt"
    kube_api_server                = format("https://api.%s:6443", var.dns.internal_zone.domain)
    kube_api_server_ca_certificate = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kube_user                      = format("system:node:%s", local.kubernetes_workers[count.index].hostname)
    kube_user_certificate          = base64encode(element(tls_locally_signed_cert.kubelet.*.cert_pem, count.index))
    kube_user_private_key          = base64encode(element(tls_private_key.kubelet.*.private_key_pem, count.index))
  }
}

resource "local_file" "kubeconfig_kubelet" {

  count = var.DEBUG ? var.kubernetes_cluster.num_workers : 0

  filename             = format("%s/kubeconfig/kubeconfig-kubelet-%s.yml",
    path.module, local.kubernetes_workers[count.index].hostname)
  content              = element(data.template_file.kubeconfig_kubelet.*.rendered, count.index)
  file_permission      = "0600"
  directory_permission = "0700"
}
