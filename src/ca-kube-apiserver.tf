resource "tls_private_key" "kube_apiserver" {

  count = var.kubernetes_cluster.num_masters

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "kube_apiserver" {

  count = var.kubernetes_cluster.num_masters

  private_key_pem = element(tls_private_key.kube_apiserver.*.private_key_pem, count.index)
  key_algorithm   = element(tls_private_key.kube_apiserver.*.algorithm, count.index)

  subject {
    common_name         = "Kubernetes"
    organization        = "API Server"
    organizational_unit = "Kubernetes The Hard Way"
    country             = "ES"
    locality            = "Madrid"
    province            = "Madrid"
  }

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.svc.cluster.local",
    format("api.%s", var.dns.internal_zone.domain),
    format("%s%02d", var.kubernetes_master.hostname, count.index),
    format("%s%02d.%s", var.kubernetes_master.hostname, count.index, var.dns.internal_zone.domain)
  ]

  ip_addresses = [
    "127.0.0.1",
    lookup(var.kubernetes_inventory,
      format("%s%02d", var.kubernetes_master.hostname, count.index)).ip_address,
    var.kubernetes_cluster.svc_network.gateway
  ]
}

resource "tls_locally_signed_cert" "kube_apiserver" {

  count = var.kubernetes_cluster.num_masters

  cert_request_pem      = element(tls_cert_request.kube_apiserver.*.cert_request_pem, count.index)
  ca_cert_pem           = tls_self_signed_cert.kube_root_ca.cert_pem
  ca_private_key_pem    = tls_private_key.kube_root_ca.private_key_pem
  ca_key_algorithm      = tls_private_key.kube_root_ca.algorithm
  validity_period_hours = 8760
  is_ca_certificate     = false
  set_subject_key_id    = true

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}

resource "local_file" "kube_apiserver_certificate_pem" {

  count = var.DEBUG ? var.kubernetes_cluster.num_masters : 0

  filename             = format("%s/ca/clients/kube-apiserver/%s%02d/certificate.pem",
    path.module, var.kubernetes_worker.hostname, count.index)
  content              = element(tls_locally_signed_cert.kube_apiserver.*.cert_pem, count.index)
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "kube_apiserver_private_key_pem" {

  count = var.DEBUG ? var.kubernetes_cluster.num_masters : 0

  filename             = format("%s/ca/clients/kube-apiserver/%s%02d/certificate.key",
    path.module, var.kubernetes_worker.hostname, count.index)
  content              = element(tls_private_key.kube_apiserver.*.private_key_pem, count.index)
  file_permission      = "0600"
  directory_permission = "0700"
}
