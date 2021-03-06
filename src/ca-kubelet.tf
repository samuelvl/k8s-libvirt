resource "tls_private_key" "kubelet" {

  count = var.kubernetes_cluster.num_workers

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "kubelet" {

  count = var.kubernetes_cluster.num_workers

  private_key_pem = element(tls_private_key.kubelet.*.private_key_pem, count.index)
  key_algorithm   = element(tls_private_key.kubelet.*.algorithm, count.index)

  subject {
    common_name         = format("system:node:%s", local.kubernetes_workers[count.index].hostname)
    organization        = "system:nodes"
    organizational_unit = "Kubernetes The Hard Way"
    country             = "ES"
    locality            = "Madrid"
    province            = "Madrid"
  }

  dns_names = [
    format("%s", local.kubernetes_workers[count.index].hostname),
    format("%s.%s", local.kubernetes_workers[count.index].hostname, var.dns.internal_zone.domain)
  ]

  ip_addresses = [
    local.kubernetes_workers[count.index].ip
  ]
}

resource "tls_locally_signed_cert" "kubelet" {

  count = var.kubernetes_cluster.num_workers

  cert_request_pem      = element(tls_cert_request.kubelet.*.cert_request_pem, count.index)
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

resource "local_file" "kubelet_certificate_pem" {

  count = var.kubernetes_cluster.num_workers

  filename             = format("%s/ca/clients/kubelet/%s/certificate.pem",
    path.module, local.kubernetes_workers[count.index].hostname)
  content              = element(tls_locally_signed_cert.kubelet.*.cert_pem, count.index)
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "kubelet_private_key_pem" {

  count = var.kubernetes_cluster.num_workers

  filename             = format("%s/ca/clients/kubelet/%s/certificate.key",
    path.module, local.kubernetes_workers[count.index].hostname)
  content              = element(tls_private_key.kubelet.*.private_key_pem, count.index)
  file_permission      = "0600"
  directory_permission = "0700"
}
