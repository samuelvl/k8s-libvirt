data "template_file" "kubeconfig_kube_admin_localhost" {

  template = file(format("%s/kubeconfig/base.yml.tpl", path.module))

  vars = {
    kube_cluster_id                = "libvirt"
    kube_api_server                = "https://127.0.0.1:6443"
    kube_api_server_ca_certificate = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kube_user                      = "admin"
    kube_user_certificate          = base64encode(tls_locally_signed_cert.kube_admin.cert_pem)
    kube_user_private_key          = base64encode(tls_private_key.kube_admin.private_key_pem)
  }
}

resource "local_file" "kubeconfig_kube_admin_localhost" {

   count = var.DEBUG ? 1 : 0

   filename             = format("%s/kubeconfig/kubeconfig-kube-admin-localhost.yml", path.module)
   content              = data.template_file.kubeconfig_kube_admin_localhost.rendered
   file_permission      = "0600"
   directory_permission = "0700"
}

data "template_file" "kubeconfig_kube_admin_public" {

  template = file(format("%s/kubeconfig/base.yml.tpl", path.module))

  vars = {
    kube_cluster_id                = "libvirt"
    kube_api_server                = format("https://api.%s:6443", var.dns.internal_zone.domain)
    kube_api_server_ca_certificate = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kube_user                      = "admin"
    kube_user_certificate          = base64encode(tls_locally_signed_cert.kube_admin.cert_pem)
    kube_user_private_key          = base64encode(tls_private_key.kube_admin.private_key_pem)
  }
}

resource "local_file" "kubeconfig_kube_admin_public" {
   filename             = format("%s/kubeconfig/kubeconfig-kube-admin.yml", path.module)
   content              = data.template_file.kubeconfig_kube_admin_public.rendered
   file_permission      = "0600"
   directory_permission = "0700"
}
