locals {
  kubernetes_masters = [
    for index in range(var.kubernetes_cluster.num_masters):
      {
        hostname = format("%s%02d", var.kubernetes_master.id, index)
        fqdn     = format("%s%02d.%s", var.kubernetes_master.id, index, var.dns.internal_zone.domain)
        ip       = lookup(var.kubernetes_inventory, format("%s%02d", var.kubernetes_master.id, index)).ip
        mac      = lookup(var.kubernetes_inventory, format("%s%02d", var.kubernetes_master.id, index)).mac
      }
  ]
}

data "template_file" "kubernetes_master_cloudinit" {

  count = var.kubernetes_cluster.num_masters

  template = file(format("%s/cloudinit/k8s-master.yml.tpl", path.module))

  vars = {
    hostname                           = local.kubernetes_masters[count.index].hostname
    fqdn                               = local.kubernetes_masters[count.index].fqdn
    ip_address                         = local.kubernetes_masters[count.index].ip
    ssh_pubkey                         = trimspace(tls_private_key.ssh_maintuser.public_key_openssh)
    kube_version                       = var.kubernetes_cluster.version
    kube_root_ca_certificate           = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kube_root_ca_private_key           = base64encode(tls_private_key.kube_root_ca.private_key_pem)
    kube_api_server_certificate        = base64encode(tls_locally_signed_cert.kube_apiserver[count.index].cert_pem)
    kube_api_server_private_key        = base64encode(tls_private_key.kube_apiserver[count.index].private_key_pem)
    kube_service_accounts_certificate  = base64encode(tls_locally_signed_cert.kube_service_accounts.cert_pem)
    kube_service_accounts_private_key  = base64encode(tls_private_key.kube_service_accounts.private_key_pem)
    kubeconfig_admin                   = base64encode(data.template_file.kubeconfig_kube_admin_localhost.rendered)
    kubeconfig_kube_controller_manager = base64encode(data.template_file.kubeconfig_kube_controller_manager.rendered)
    kubeconfig_kube_scheduler          = base64encode(data.template_file.kubeconfig_kube_scheduler.rendered)
    kube_svc_network_cidr              = var.kubernetes_cluster.svc_network.cidr
    kube_pod_network_cidr              = var.kubernetes_cluster.pod_network.cidr
    kube_nodeport_range                = var.kubernetes_cluster.node_port_range
    etcd_version                       = var.etcd_cluster.version
    etcd_member_name                   = local.etcd_cluster[count.index].id
    etcd_member_ip                     = local.kubernetes_masters[count.index].ip
    etcd_initial_cluster               = local.etcd_initial_cluster
    etcd_servers                       = join(",", local.etcd_cluster.*.urls.server)
    etcd_root_ca                       = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    etcd_member_certificate            = base64encode(tls_locally_signed_cert.kube_apiserver[count.index].cert_pem)
    etcd_member_private_key            = base64encode(tls_private_key.kube_apiserver[count.index].private_key_pem)
    etcd_encryption_config             = base64encode(data.template_file.etcd_encryption_key.rendered)
  }
}

resource "libvirt_cloudinit_disk" "kubernetes_master" {

  count = var.kubernetes_cluster.num_masters

  name      = format("cloudinit-%s.qcow2", local.kubernetes_masters[count.index].hostname)
  pool      = libvirt_pool.kubernetes.name
  user_data = element(data.template_file.kubernetes_master_cloudinit.*.rendered, count.index)
}

resource "libvirt_volume" "kubernetes_master_image" {

  count = var.kubernetes_cluster.num_masters

  name   = format("%s-baseimg.qcow2", local.kubernetes_masters[count.index].hostname)
  pool   = libvirt_pool.kubernetes.name
  source = var.kubernetes_master.base_img
  format = "qcow2"
}

resource "libvirt_volume" "kubernetes_master" {

  count = var.kubernetes_cluster.num_masters

  name           = format("%s-volume.qcow2", local.kubernetes_masters[count.index].hostname)
  pool           = libvirt_pool.kubernetes.name
  base_volume_id = element(libvirt_volume.kubernetes_master_image.*.id, count.index)
  format         = "qcow2"
}

resource "libvirt_domain" "kubernetes_master" {

  count = var.kubernetes_cluster.num_masters

  name   = format("k8s-%s", local.kubernetes_masters[count.index].hostname)
  memory = var.kubernetes_master.memory
  vcpu   = var.kubernetes_master.vcpu

  cloudinit = element(libvirt_cloudinit_disk.kubernetes_master.*.id, count.index)

  disk {
    volume_id = element(libvirt_volume.kubernetes_master.*.id, count.index)
    scsi      = false
  }

  network_interface {
    network_name   = libvirt_network.kubernetes.name
    hostname       = format("%s.%s", local.kubernetes_masters[count.index].hostname, var.dns.internal_zone.domain)
    addresses      = [ local.kubernetes_masters[count.index].ip ]
    mac            = local.kubernetes_masters[count.index].mac
    wait_for_lease = true
  }

  console {
    type           = "pty"
    target_type    = "serial"
    target_port    = "0"
    source_host    = "127.0.0.1"
    source_service = "0"
  }

  graphics {
    type           = "spice"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  provisioner "local-exec" {
    when    = destroy
    command = format("ssh-keygen -R %s || true", self.network_interface.0.hostname)
  }
}
