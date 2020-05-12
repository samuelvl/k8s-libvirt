resource "tls_private_key" "kube_service_accounts" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "kube_service_accounts" {
  private_key_pem = tls_private_key.kube_service_accounts.private_key_pem
  key_algorithm   = tls_private_key.kube_service_accounts.algorithm

  subject {
    common_name         = "service-accounts"
    organization        = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    country             = "ES"
    locality            = "Madrid"
    province            = "Madrid"
  }
}

resource "tls_locally_signed_cert" "kube_service_accounts" {
  cert_request_pem      = tls_cert_request.kube_service_accounts.cert_request_pem
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