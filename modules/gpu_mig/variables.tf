variable "name" { type = string }
variable "region" { type = string }
variable "network" { type = string }
variable "subnetwork" { type = string }
variable "service_account_email" { type = string }
variable "machine_type" { type = string default = "g2-standard-8" }
variable "accelerator_type" { type = string default = "nvidia-l4" }
variable "accelerator_count" { type = number default = 1 }
variable "source_image" { type = string default = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts" }
variable "boot_disk_gb" { type = number default = 50 }
variable "docker_image" { type = string }
variable "port" { type = number default = 9000 }
variable "size" { type = number default = 1 }
variable "startup_script" { type = string default = null }
variable "labels" { type = map(string) default = {} }
variable "tags" { type = list(string) default = ["http-server","https-server"] }
