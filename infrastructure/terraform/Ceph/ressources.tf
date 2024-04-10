resource "proxmox_vm_qemu" "ceph" {
    name = "serv-pa-ceph-00${count.index}"
    desc = "terrafom VPS"
    vmid = "serv-pa-ceph-00${count.index}"
    target_node = "" # Nom a mettre en place
    
    clone = var.os_type
    cores = var.proc
    sockets = 1
    memory = var.memoires

    network {
        bridge = "vmbr1"
        model = "virtio"
    }

    disk {
        storage = "" # nom storage
        type = "virtio"
        size = "20G"
    }
    // disque secondaire
    disk {
        storage = "" # nom storage
        type = "virtio"
        size = "50G"
    }
    disk {
        storage = "" # nom storage
        type = "virtio"
        size = "50G"
    }

    os_type = "cloud-init"
    ipconfig0 = "ip=172.16.0.10/16,qw=172.16.0.254"
    nameserver = var.nameserver
    ciuser = "admuser"
    sshkeys = var.sshkeys_user

    count = var.workers_count

}