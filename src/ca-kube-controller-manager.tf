resource "tls_private_key" "kube_controller_manager" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "kube_controller_manager" {
  private_key_pem = tls_private_key.kube_controller_manager.private_key_pem
  key_algorithm   = tls_private_key.kube_controller_manager.algorithm

  subject {
    common_name         = "system:kube-controller-manager"
    organization        = "system:kube-controller-manager"
    organizational_unit = "Kubernetes The Hard Way"
    country             = "ES"
    locality            = "Madrid"
    province            = "Madrid"
  }
}

resource "tls_locally_signed_cert" "kube_controller_manager" {
  cert_request_pem      = tls_cert_request.kube_controller_manager.cert_request_pem
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