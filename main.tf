terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider libvirt {
  uri = "qemu:///system"
}

# variable

variable "control_plane" {
  type = list(string)
  default = [ "coreos-master-01", "coreos-master-02", "coreos-master-03" ]
}

variable "worker" {
  type = list(string)
  default = [ "coreos-worker-01", "coreos-worker-02" ]
}

# Setup network

resource "libvirt_network" "kube_network" {
  name = "core-k8s"
  mode = "nat"
  domain = "k8s.local"
  addresses = ["10.10.10.0/24"]
  autostart = true
  dns {
    enabled = true
    forwarders {
      address = "192.168.100.15"
    }
  }
}

# pool disk setup 

resource "libvirt_pool" "coreos_cluster" {
  name = "coreos_cluster"
  type = "dir"
  path = "/data/coreos-cluster"
}

# volume setup

resource "libvirt_volume" "coreos" {
  name = "coreos"
  source = "/data/isos/coreos.qcow2"
  format = "qcow2"
  pool = libvirt_pool.coreos_cluster.name
}

resource "libvirt_volume" "control_plane" {
  count = length(var.control_plane)

  name = "${var.control_plane[count.index]}.qcow2"
  base_volume_id = libvirt_volume.coreos.id
  pool = libvirt_pool.coreos_cluster.name
  size = 53687091200
  format = "qcow2"
}

resource "libvirt_volume" "worker" {
  count = length(var.worker)

  name = "${var.worker[count.index]}.qcow2"
  base_volume_id = libvirt_volume.coreos.id
  pool = libvirt_pool.coreos_cluster.name
  size = 75161927680
  format = "qcow2"
}

# ignition config

resource "libvirt_ignition" "user" {
  name = "user.ign"
  content = "./template.ign"
  pool = libvirt_pool.coreos_cluster.name
}

# domain 

resource "libvirt_domain" "control_plane" {
  count = length(var.control_plane)

  name = var.control_plane[count.index]
  memory = 4096
  vcpu = 4

  network_interface {
    network_id = libvirt_network.kube_network.id
    hostname = var.control_plane[count.index]
    addresses = ["10.10.10.1${count.index}"]
  }

  disk {
    volume_id = libvirt_volume.control_plane[count.index].id
  }

  coreos_ignition = libvirt_ignition.user.id
}

resource "libvirt_domain" "worker" {
  count = length(var.worker)

  name = var.worker[count.index]
  memory = 4096
  vcpu = 4

  network_interface {
    network_id = libvirt_network.kube_network.id
    hostname = var.worker[count.index]
    addresses = ["10.10.10.2${count.index}"]
  }

  disk {
    volume_id = libvirt_volume.worker[count.index].id
  }

  coreos_ignition = libvirt_ignition.user.id
}