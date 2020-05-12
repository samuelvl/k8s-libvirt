resource "libvirt_ignition" "load_balancer" {
  name    = format("%s.ign", var.load_balancer.hostname)
  pool    = libvirt_pool.kubernetes.name
  content = file(format("%s/ignition/load-balancer/ignition.json", path.module))
}

resource "libvirt_volume" "load_balancer_image" {
  name   = format("%s-baseimg.qcow2", var.load_balancer.hostname)
  pool   = libvirt_pool.kubernetes.name
  source = var.load_balancer.base_img
  format = "qcow2"
}

resource "libvirt_volume" "load_balancer" {
  name           = format("%s-volume.qcow2", var.load_balancer.hostname)
  pool           = libvirt_pool.kubernetes.name
  base_volume_id = libvirt_volume.load_balancer_image.id
  format         = "qcow2"
}

resource "libvirt_domain" "load_balancer" {
  name   = format("k8s-%s", var.load_balancer.hostname)
  memory = var.load_balancer.memory
  vcpu   = var.load_balancer.vcpu

  coreos_ignition = libvirt_ignition.load_balancer.id

  disk {
    volume_id = libvirt_volume.load_balancer.id
    scsi      = false
  }

  network_interface {
    hostname       = format("%s.%s", var.load_balancer.hostname, var.dns.internal_zone.domain)
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

  provisioner "local-exec" {
    when    = destroy
    command = format("ssh-keygen -R %s", self.network_interface.0.hostname)
  }
}
