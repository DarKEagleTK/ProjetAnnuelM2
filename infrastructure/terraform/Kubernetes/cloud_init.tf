# initialisation des fichiers cloud inits
data "template_file" "user_data" {
  template = file("./cloud_init/cloud_init.cfg")
  vars = {
    hostname = "serv-pa-kubernetes-00${count.index}"
    fqdn = "serv-pa-kubernetes-00${count.index}"
  }
}
data "template_file" "network_config" {
  template = file("./cloud_init/network_config.cfg")
  vars = {
    ip = "10.1.0.15${count.index}/16"
    gateway = var.gateway
    nameserver = var.nameserver
  }
}

data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = "${data.template_file.user_data.rendered}"
  }
}

# Creation du disque cloud init
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "serv-pa-kubernetes-00${count.index}-commoninit.iso"
  pool = libvirt_pool.pa-kubernetes.name
  user_data      = data.template_cloudinit_config.config.rendered
  network_config = data.template_file.network_config.rendered

  count = var.workers_count

  depends_on = [ libvirt_pool.local ]
}