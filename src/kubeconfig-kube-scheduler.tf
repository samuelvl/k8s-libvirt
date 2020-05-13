data "template_file" "kubeconfig_kube_scheduler" {

  template = file(format("%s/kubeconfig/base.yml.tpl", path.module))

  vars = {
    kube_api_server                = "https://127.0.0.1:6443"
    kube_api_server_ca_certificate = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kube_user                      = "system:kube-scheduler"
    kube_user_certificate          = base64encode(tls_locally_signed_cert.kube_scheduler.cert_pem)
    kube_user_private_key          = base64encode(tls_private_key.kube_scheduler.private_key_pem)
  }
}

resource "local_file" "kubeconfig_kube_scheduler" {

  count = var.DEBUG ? 1 : 0

  filename             = format("%s/kubeconfig/kubeconfig-kube-scheduler.yml", path.module)
  content              = data.template_file.kubeconfig_kube_scheduler.rendered
  file_permission      = "0600"
  directory_permission = "0700"
}
