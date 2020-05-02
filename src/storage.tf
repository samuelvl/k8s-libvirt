resource "libvirt_pool" "kubernetes" {
  name = var.libvirt.pool
  type = "dir"
  path = var.libvirt.pool_path
}