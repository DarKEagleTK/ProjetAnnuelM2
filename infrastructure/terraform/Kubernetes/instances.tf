// Create the machine
resource "libvirt_domain" "domain" {
  name = "${var.hostname}"
  memory = var.memoryMB
  vcpu = var.cpu

  disk {
    volume_id = "${element(libvirt_volume.main_disque.*.id, count.index)}"
  }
  network_interface {
    network_name = var.network_name
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id
  #qemu_agent = true

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  graphics {
    type = "vnc"
    listen_type = "address"
    autoport = "true"
  }
  cpu {
    mode = "host-passthrough"
  }

  count = var.workers_count
  depends_on = [ libvirt_pool.local ]
}

output "ips" {
  value = "${flatten(libvirt_domain.domain.*.network_interface.0.addresses)}"
}