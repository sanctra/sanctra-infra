variable "name" { type = string }
variable "labels" { type = map(string) default = {} }
variable "initial_value" { type = string default = null }
