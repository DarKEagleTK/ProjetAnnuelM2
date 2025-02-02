# Dossier pour les disques
resource "libvirt_pool" "pa-kubernetes" {
    name = "local"
    type = "dir"
    path = "/mnt/storage-local/vm-disk/vm-pa-kubernetes"
}

# disque base
resource "libvirt_volume" "master_debian11" {
    name = "master_debian11"
    pool = libvirt_pool.pa-kubernetes.name
    source = "/mnt/storage-local/vm-disk/templates/jammy-server-cloudimg-amd64-disk-kvm.img"
}

# Disque pour la VM
resource "libvirt_volume" "main_disque" {
    name = "serv-pa-kubernetes-00${count.index}-disque"
    pool = libvirt_pool.pa-kubernetes.name
    base_volume_id = libvirt_volume.master_debian11.id
    size = 21474836480 # 20Gb
    count = var.workers_count
}
