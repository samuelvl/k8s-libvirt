locals {
  kubernetes_workers_ip = [
    for worker_index in range(var.kubernetes_cluster.num_workers) :
      lookup(var.kubernetes_inventory, format("%s%02d", var.kubernetes_worker.hostname, worker_index)).ip_address
  ]
  kubernetes_workers_mac = [
    for worker_index in range(var.kubernetes_cluster.num_workers) :
      lookup(var.kubernetes_inventory, format("%s%02d", var.kubernetes_worker.hostname, worker_index)).mac_address
  ]
  kubernetes_workers_hostpod_network = [
    for worker_index in range(var.kubernetes_cluster.num_workers) :
      format("%s.%s.0/24",
        join(".", slice(split(".", var.kubernetes_cluster.pod_network.cidr), 0, 2)), worker_index)
  ]
}

data "template_file" "kubernetes_worker_cloudinit" {

  count = var.kubernetes_cluster.num_workers

  template = file(format("%s/cloudinit/k8s-worker.yml.tpl", path.module))

  vars = {
    hostname   = format("%s%02d", var.kubernetes_worker.hostname, count.index)
    fqdn       = format("%s%02d.%s", var.kubernetes_worker.hostname, count.index, var.dns.internal_zone.domain)
    ssh_pubkey = trimspace(tls_private_key.ssh_maintuser.public_key_openssh)

    kube_version              = var.kubernetes_cluster.version
    crio_version              = var.kubernetes_cluster.crio_version
    kube_pod_network_cidr     = var.kubernetes_cluster.pod_network.cidr
    kube_hostpod_network_cidr = element(local.kubernetes_workers_hostpod_network, count.index)
    kube_root_ca_certificate  = base64encode(tls_self_signed_cert.kube_root_ca.cert_pem)
    kubelet_certificate       = base64encode(element(tls_locally_signed_cert.kubelet.*.cert_pem, count.index))
    kubelet_private_key       = base64encode(element(tls_private_key.kubelet.*.private_key_pem, count.index))
    kubeconfig_kubelet        = base64encode(element(data.template_file.kubeconfig_kubelet.*.rendered, count.index))
    kube_dns_server           = var.kubernetes_cluster.dns_server
    kubeconfig_kube_proxy     = base64encode(data.template_file.kubeconfig_kube_proxy.rendered)
  }
}

resource "libvirt_cloudinit_disk" "kubernetes_worker" {

  count = var.kubernetes_cluster.num_workers

  name      = format("cloudinit-%s%02d.qcow2", var.kubernetes_worker.hostname, count.index)
  pool      = libvirt_pool.kubernetes.name
  user_data = element(data.template_file.kubernetes_worker_cloudinit.*.rendered, count.index)
}

resource "libvirt_volume" "kubernetes_worker_image" {

  count = var.kubernetes_cluster.num_workers

  name   = format("%s%02d-baseimg.qcow2", var.kubernetes_worker.hostname, count.index)
  pool   = libvirt_pool.kubernetes.name
  source = var.kubernetes_worker.base_img
  format = "qcow2"
}

resource "libvirt_volume" "kubernetes_worker" {

  count = var.kubernetes_cluster.num_workers

  name           = format("%s%02d-volume.qcow2", var.kubernetes_worker.hostname, count.index)
  pool           = libvirt_pool.kubernetes.name
  base_volume_id = element(libvirt_volume.kubernetes_worker_image.*.id, count.index)
  format         = "qcow2"
}

resource "libvirt_domain" "kubernetes_worker" {

  count = var.kubernetes_cluster.num_workers

  name   = format("k8s-%s%02d", var.kubernetes_worker.hostname, count.index)
  memory = var.kubernetes_worker.memory
  vcpu   = var.kubernetes_worker.vcpu

  cloudinit = element(libvirt_cloudinit_disk.kubernetes_worker.*.id, count.index)

  disk {
    volume_id = element(libvirt_volume.kubernetes_worker.*.id, count.index)
    scsi      = false
  }

  network_interface {
    network_name   = libvirt_network.kubernetes.name
    hostname       = format("%s%02d.%s", var.kubernetes_worker.hostname, count.index, var.dns.internal_zone.domain)
    addresses      = [ element(local.kubernetes_workers_ip, count.index) ]
    mac            = element(local.kubernetes_workers_mac, count.index)
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
