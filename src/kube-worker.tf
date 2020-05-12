data "template_file" "kubernetes_worker_cloudinit" {

  count = var.kubernetes_cluster.num_workers

  template = file(format("%s/cloudinit/k8s-worker/cloudinit.yml", path.module))

  vars = {
    hostname   = format("%s%02d", var.kubernetes_worker.hostname, count.index)
    fqdn       = format("%s%02d.%s", var.kubernetes_worker.hostname, count.index, var.dns.internal_zone.domain)
    ssh_pubkey = trimspace(file(format("%s/ssh/maintuser/id_rsa.pub", path.module)))
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
    hostname       = format("%s%02d.%s", var.kubernetes_worker.hostname, count.index, var.dns.internal_zone.domain)
    network_name   = libvirt_network.kubernetes.name
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
}
