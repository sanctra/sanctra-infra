variable "name" { type = string }
variable "region" { type = string }
variable "image" { type = string }
variable "port"  { type = number default = 8080 }
variable "env"   { type = map(string) default = {} }
variable "allow_unauth" { type = bool default = false }
variable "ingress" { type = string default = "INGRESS_TRAFFIC_ALL" }
variable "service_account_email" { type = string default = null }
variable "labels" { type = map(string) default = {} }
