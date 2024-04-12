terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

# Configure the Libvirt provider
provider "libvirt" {
  #uri = "qemu+ssh://admuser@192.168.0.10/system"
  uri = "qemu:///system"
}
