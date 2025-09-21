terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
  }
}

resource "google_secret_manager_secret" "this" {
  secret_id = var.name
  replication {
    auto {}
  }
  labels = var.labels
}

# Optionally create an initial version by supplying var.initial_value
resource "google_secret_manager_secret_version" "initial" {
  count       = var.initial_value == null ? 0 : 1
  secret      = google_secret_manager_secret.this.id
  secret_data = var.initial_value
}
