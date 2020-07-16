locals {
  etcd_cluster = [
    for index in range(var.kubernetes_cluster.num_masters):
      {
        id   = format("etcd-member%02d", index)
        urls = {
          server = format("https://%s:2379", local.kubernetes_masters[index].ip)
          peer   = format("https://%s:2380", local.kubernetes_masters[index].ip)
        }
      }
  ]

  etcd_initial_cluster = join(",", formatlist("%s=%s", local.etcd_cluster.*.id, local.etcd_cluster.*.urls.peer))
}

resource "random_string" "etcd_encryption_key" {
  length      = 32
  upper       = true
  min_upper   = 8
  lower       = true
  min_lower   = 8
  number      = true
  min_numeric = 8
  special     = true
  min_special = 8
}

data "template_file" "etcd_encryption_key" {

  template = file(format("%s/etcd/encryption-config.yml.tpl", path.module))

  vars = {
    etcd_encryption_key = base64encode(random_string.etcd_encryption_key.result)
  }
}

resource "local_file" "etcd_encryption_key" {

   count = var.DEBUG ? 1 : 0

   filename             = format("%s/etcd/encryption-config.yml", path.module)
   content              = data.template_file.etcd_encryption_key.rendered
   file_permission      = "0600"
   directory_permission = "0700"
}
