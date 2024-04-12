variable "memoryMB" { 
    default = 1024*4 
}
variable "cpu" { 
    default = 4
}

variable gateway {
  default = "10.1.0.254"
}

variable nameserver {
  default = "192.168.0.254"
}

variable network_name {
  default = "TGT"
}

variable workers_count {
    default = 3
}