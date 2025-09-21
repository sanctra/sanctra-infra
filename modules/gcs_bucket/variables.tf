variable "name" { type = string }
variable "location" { type = string }
variable "uniform_bucket_level_access" { type = bool  default = true }
variable "force_destroy" { type = bool  default = false }
variable "versioning" { type = bool default = false }
variable "storage_class" { type = string default = "STANDARD" }
variable "lifecycle_delete_age" { type = number default = 0 }
variable "labels" { type = map(string) default = {} }
