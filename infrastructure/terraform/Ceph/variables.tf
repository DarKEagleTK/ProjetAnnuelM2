variable "admuser" {
    default = "terraform"
}

variable "pm_uri_url" {
    default = "https://ip:8006/api2/json" # ip a modifier
}

variable "pm_user" {
    default = "terraform@pam!terraform"
}

variable "pm_password" {
    default = ""
}

variable "os_type" {
  default = "" # nom_template
}

variable "nameserver" {
  default = "" # A modifier
}

variable "sshkeys_user" {
  default = "" # a modifier pour liste
}

variable "memoires" {
  default = 1024*6
}

variable "proc" {
  default = 4
}

variable workers_count {
    default = 3
}