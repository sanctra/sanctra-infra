terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
  }
}

resource "google_cloud_run_v2_service" "this" {
  name     = var.name
  location = var.region
  ingress  = var.ingress

  template {
    service_account = var.service_account_email
    containers {
      image = var.image
      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }
      ports {
        name           = "http1"
        container_port = var.port
      }
    }
  }

  labels = var.labels
}

# Allow unauthenticated if requested
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  count   = var.allow_unauth ? 1 : 0
  name    = google_cloud_run_v2_service.this.name
  location = var.region
  role    = "roles/run.invoker"
  member  = "allUsers"
}
