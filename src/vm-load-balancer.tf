locals {
  load_balancer_ip  = lookup(var.kubernetes_inventory, var.load_balancer.hostname).ip_address
  load_balancer_mac = lookup(var.kubernetes_inventory, var.load_balancer.hostname).mac_address
}

data "template_file" "load_balancer_ignition" {
  template = file(format("%s/ignition/load-balancer/ignition.json.tpl", path.module))

  vars = {
    fqdn             = format("%s.%s", var.load_balancer.hostname, var.dns.internal_zone.domain)
    ssh_pubkey       = trimspace(file(format("%s/ssh/maintuser/id_rsa.pub", path.module)))
    ha_proxy_version = var.load_balancer.ha_proxy_version
    ha_proxy_max_cpu = format("%.3f", var.load_balancer.vcpu)
    ha_proxy_max_mem = format("%dm", var.load_balancer.memory)
  }
}

resource "libvirt_ignition" "load_balancer" {
  name    = format("%s.ign", var.load_balancer.hostname)
  pool    = libvirt_pool.kubernetes.name
  content = data.template_file.load_balancer_ignition.rendered
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
    network_name   = libvirt_network.kubernetes.name
    hostname       = format("%s.%s", var.load_balancer.hostname, var.dns.internal_zone.domain)
    addresses      = [ local.load_balancer_ip ]
    mac            = local.load_balancer_mac
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
