# Dossier pour les disques
resource "libvirt_pool" "pa-ceph" {
    name = "pa-ceph"
    type = "dir"
    path = "/mnt/storage-local/vm-disk/vm-pa-ceph"
}

# disque base
resource "libvirt_volume" "master_debian11" {
    name = "master_debian11"
    pool = libvirt_pool.pa-ceph.name
    source = "/mnt/storage-local/vm-disk/templates/debian-11-cloud-init-base.qcow2"
}

# Disque pour la VM
resource "libvirt_volume" "main_disque" {
    name = "serv-pa-ceph-00${count.index}-disque"
    pool = libvirt_pool.pa-ceph.name
    base_volume_id = libvirt_volume.master_debian11.id
    size = 21474836480 # 20Gb
    count = var.workers_count
}

# Disque supplementaire
resource "libvirt_volume" "disque2" {
    name = "serv-pa-ceph-00${count.index}-disque2"
    pool = libvirt_pool.pa-ceph.name
    size = 21474836480 # 20Gb
    count = var.workers_count
}
resource "libvirt_volume" "disque3" {
    name = "serv-pa-ceph-00${count.index}-disque3"
    pool = libvirt_pool.pa-ceph.name
    size = 21474836480 # 20Gb
    count = var.workers_count
}