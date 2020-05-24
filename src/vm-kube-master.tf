locals {
  kubernetes_masters_ip = [
    for master_index in range(var.kubernetes_cluster.num_masters) :
      lookup(var.kubernetes_inventory, format("%s%02d", var.kubernetes_master.hostname, master_index)).ip_address
  ]
  kubernetes_masters_mac = [
    for master_index in range(var.kubernetes_cluster.num_masters) :
      lookup(var.kubernetes_inventory, format("%s%02d", var.kubernetes_master.hostname, master_index)).mac_address
  ]
}

locals {
  etcd_members = formatlist("etcd-member%02d", range(var.kubernetes_cluster.num_masters))
  etcd_servers = [
    for member_index in range(var.kubernetes_cluster.num_masters) :
      format("https://%s:2379", element(local.kubernetes_masters_ip, member_index))
  ]
  etcd_peers   = [
    for member_index in range(var.kubernetes_cluster.num_masters) :
      format("%s=https://%s:2380",
        element(local.etcd_members, member_index),
        element(local.kubernetes_masters_ip, member_index))
  ]
}

data "template_file" "kubernetes_master_cloudinit" {

  count = var.kubernetes_cluster.num_masters

  template = file(format("%s/cloudinit/k8s-master.yml.tpl", path.module))

  vars = {
    ip_address = element(local.kubernetes_masters_ip, count.index)
    hostname   = format("%s%02d", var.kubernetes_master.hostname, count.index)
    fqdn       = format("%s%02d.%s", var.kubernetes_master.hostname, count.index, var.dns.internal_zone.domain)
    ssh_pubkey = trimspace(tls_private_key.ssh_maintuser.public_key_openssh)

    etcd_version            = var.kubernetes_cluster.etcd_version
    etcd_member_name        = element(local.etcd_members, count.index)
    etcd_member_ip          = element(local.kubernetes_masters_ip, count.index)
    etcd_initial_cluster    = join(",", local.etcd_peers)
    etcd_servers            = join(",", local.etcd_servers)
    etcd_root_ca            = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    etcd_member_certificate = base64encode(element(tls_locally_signed_cert.kube_apiserver.*.cert_pem, count.index))
    etcd_member_private_key = base64encode(element(tls_private_key.kube_apiserver.*.private_key_pem, count.index))
    etcd_encryption_config  = base64encode(data.template_file.etcd_encryption_key.rendered)

    kube_version                       = var.kubernetes_cluster.version
    kube_root_ca_certificate           = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kube_root_ca_private_key           = base64encode(tls_private_key.kube_root_ca.private_key_pem)
    kube_api_server_certificate        = base64encode(element(tls_locally_signed_cert.kube_apiserver.*.cert_pem, count.index))
    kube_api_server_private_key        = base64encode(element(tls_private_key.kube_apiserver.*.private_key_pem, count.index))
    kube_service_accounts_certificate  = base64encode(tls_locally_signed_cert.kube_service_accounts.cert_pem)
    kube_service_accounts_private_key  = base64encode(tls_private_key.kube_service_accounts.private_key_pem)
    kube_svc_network_cidr              = var.kubernetes_cluster.svc_network.cidr
    kube_pod_network_cidr              = var.kubernetes_cluster.pod_network.cidr
    kube_nodeport_range                = var.kubernetes_cluster.node_port_range
    kubeconfig_kube_controller_manager = base64encode(data.template_file.kubeconfig_kube_controller_manager.rendered)
    kubeconfig_kube_scheduler          = base64encode(data.template_file.kubeconfig_kube_scheduler.rendered)
    kubeconfig_admin                   = base64encode(data.template_file.kubeconfig_kube_admin_localhost.rendered)
  }
}

resource "libvirt_cloudinit_disk" "kubernetes_master" {

  count = var.kubernetes_cluster.num_masters

  name      = format("cloudinit-%s%02d.qcow2", var.kubernetes_master.hostname, count.index)
  pool      = libvirt_pool.kubernetes.name
  user_data = element(data.template_file.kubernetes_master_cloudinit.*.rendered, count.index)
}

resource "libvirt_volume" "kubernetes_master_image" {

  count = var.kubernetes_cluster.num_masters

  name   = format("%s%02d-baseimg.qcow2", var.kubernetes_master.hostname, count.index)
  pool   = libvirt_pool.kubernetes.name
  source = var.kubernetes_master.base_img
  format = "qcow2"
}

resource "libvirt_volume" "kubernetes_master" {

  count = var.kubernetes_cluster.num_masters

  name           = format("%s%02d-volume.qcow2", var.kubernetes_master.hostname, count.index)
  pool           = libvirt_pool.kubernetes.name
  base_volume_id = element(libvirt_volume.kubernetes_master_image.*.id, count.index)
  format         = "qcow2"
}

resource "libvirt_domain" "kubernetes_master" {

  count = var.kubernetes_cluster.num_masters

  name   = format("k8s-%s%02d", var.kubernetes_master.hostname, count.index)
  memory = var.kubernetes_master.memory
  vcpu   = var.kubernetes_master.vcpu

  cloudinit = element(libvirt_cloudinit_disk.kubernetes_master.*.id, count.index)

  disk {
    volume_id = element(libvirt_volume.kubernetes_master.*.id, count.index)
    scsi      = false
  }

  network_interface {
    network_name   = libvirt_network.kubernetes.name
    hostname       = format("%s%02d.%s", var.kubernetes_master.hostname, count.index, var.dns.internal_zone.domain)
    addresses      = [ element(local.kubernetes_masters_ip, count.index) ]
    mac            = element(local.kubernetes_masters_mac, count.index)
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
