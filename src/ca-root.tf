resource "tls_private_key" "kube_root_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "kube_root_ca" {
  private_key_pem       = tls_private_key.kube_root_ca.private_key_pem
  key_algorithm         = tls_private_key.kube_root_ca.algorithm
  validity_period_hours = 87600
  is_ca_certificate     = true
  set_subject_key_id    = true

  subject {
    common_name         = "Kubernetes Root CA"
    organization        = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    country             = "ES"
    locality            = "Madrid"
    province            = "Madrid"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
}