data "template_file" "kubeconfig_kube_proxy" {

  template = file(format("%s/kubeconfig/base.yml.tpl", path.module))

  vars = {
    kube_api_server                = format("https://api.%s:6443", var.dns.internal_zone.domain)
    kube_api_server_ca_certificate = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kube_user                      = "system:kube-proxy"
    kube_user_certificate          = base64encode(tls_locally_signed_cert.kube_proxy.cert_pem)
    kube_user_private_key          = base64encode(tls_private_key.kube_proxy.private_key_pem)
  }
}

resource "local_file" "kubeconfig_kube_proxy" {

  count = var.DEBUG ? 1 : 0

  filename             = format("%s/kubeconfig/kubeconfig-kube-proxy.yml", path.module)
  content              = data.template_file.kubeconfig_kube_proxy.rendered
  file_permission      = "0600"
  directory_permission = "0700"
}
