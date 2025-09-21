terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
  }
}

resource "google_storage_bucket" "this" {
  name                        = var.name
  location                    = var.location
  uniform_bucket_level_access = var.uniform_bucket_level_access
  force_destroy               = var.force_destroy
  storage_class               = var.storage_class

  versioning {
    enabled = var.versioning
  }

  lifecycle_rule {
    condition {
      age = var.lifecycle_delete_age
    }
    action {
      type = "Delete"
    }
    count = var.lifecycle_delete_age > 0 ? 1 : 0
  }

  labels = var.labels
}
