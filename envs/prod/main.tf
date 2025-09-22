terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.40"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Artifact Registry: single Docker repo
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "sanctra-docker"
  description   = "Sanctra Docker images"
  format        = "DOCKER"
}

# Buckets
module "bucket_renders" {
  source   = "../../modules/gcs_bucket"
  name     = "avatars-renders-${var.project_id}"
  location = var.location
  labels   = { app = "sanctra", purpose = "renders" }
}

module "bucket_uploads" {
  source   = "../../modules/gcs_bucket"
  name     = "sanctra-uploads-${var.project_id}"
  location = var.location
  labels   = { app = "sanctra", purpose = "uploads" }
}

module "bucket_logs" {
  source               = "../../modules/gcs_bucket"
  name                 = "sanctra-logs-${var.project_id}"
  location             = var.location
  labels               = { app = "sanctra", purpose = "logs" }
  lifecycle_delete_age = 30
}

# Secrets

module "secret_gemini" {
  source = "../../modules/secret"
  name   = "GEMINI_API_KEY"
}

# Cloud Run services
module "run_orchestrator" {
  source                  = "././modules/cloud_run_service"
  name                    = "sanctra-orchestrator"
  region                  = var.region
  image                   = var.orchestrator_image
  allow_unauth            = true
  port                    = 8080
  env = {
    AVATAR_RENDERS_BUCKET = module.bucket_renders.name
    RAG_SERVICE_URL       = module.run_rag.uri
    # NEW: wire upstreams (replace with your LB URLs or internal DNS names)
    ASR_SERVICE_URL       = "ws://asr-gpu.internal.sanctra:9000"
    AVATAR_SERVICE_URL    = "http://avatar-gpu.internal.sanctra:9100"
    TTS_SERVICE_HTTP_URL  = "http://tts-gpu.internal.sanctra:9200"
    TTS_SERVICE_WS_URL    = "ws://tts-gpu.internal.sanctra:9200"
    AVATAR_UPLOADS_BUCKET = module.bucket_uploads.name
  }
  service_account_email   = var.run_sa_email
  labels                  = { app = "sanctra", svc = "orchestrator" }
}


module "run_rag" {
  source       = "../../modules/cloud_run_service"
  name         = "sanctra-rag-service"
  region       = var.region
  image        = var.rag_image
  allow_unauth = false # Make RAG service private
  port         = 8080
  env = {
    GCP_PROJECT         = var.project_id
    GCP_LOCATION        = var.region
    VERTEX_INDEX_ID     = google_vertex_ai_index.sanctra.name
    VERTEX_INDEX_ENDPOINT_ID = google_vertex_ai_index_endpoint.sanctra.name
    VERTEX_EMBED_MODEL  = var.vertex_embedding_model
  }
  service_account_email = var.run_sa_email
  labels                = { app = "sanctra", svc = "rag" }
}

# Grant the Orchestrator's service account permission to invoke the private RAG service
resource "google_cloud_run_v2_service_iam_member" "rag_invoker" {
  project  = module.run_rag.project
  location = module.run_rag.location
  name     = module.run_rag.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.run_sa_email}"
}


# GPU MIGs (stubs)
module "mig_asr" {
  source                  = "../../modules/gpu_mig"
  name                    = "sanctra-asr-gpu"
  region                  = var.region
  network                 = var.network
  subnetwork              = var.subnetwork
  service_account_email   = var.gpu_sa_email
  docker_image            = var.asr_image
  port                    = 9000
  labels                  = { app = "sanctra", svc = "asr" }
}

# TTS GPU MIG
module "tts_gpu" {
  source       = "../../modules/gpu_mig"
  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  name         = "sanctra-tts-gpu"
  machine_type = "g2-standard-4"            # L4 GPU family often maps to g2.* on GCP
  gpu_type     = "nvidia-l4"                # adjust if your module expects enum
  gpu_count    = 1
  min_replicas = 1
  max_replicas = 4
  port         = 9200

  # Container image pushed by cloudbuild/tts-gpu.yaml
  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/sanctra-docker/sanctra-tts-gpu:${var.image_tag}"

  # Environment for the container
  env = {
    MODEL_NAME         = "tts_models/multilingual/multi-dataset/your_tts"
    SAMPLE_RATE        = "24000"
    DEVICE             = "cuda"
  }

  # Optional HTTP health check path
  health_check_path = "/healthz"
}

module "mig_avatar" {
  source                  = "../../modules/gpu_mig"
  name                    = "sanctra-avatar-gpu"
  region                  = var.region
  network                 = var.network
  subnetwork              = var.subnetwork
  service_account_email   = var.gpu_sa_email
  docker_image            = var.avatar_image
  port                    = 9100
  labels                  = { app = "sanctra", svc = "avatar" }
}

module "mig_tts" {
  source                = "././modules/gpu_mig"
  name                  = "sanctra-tts-gpu"
  region                = var.region
  network               = var.network
  subnetwork            = var.subnetwork
  service_account_email = var.gpu_sa_email
  docker_image          = var.tts_image
  port                  = 9200
  labels                = { app = "sanctra", svc = "tts" }
}

# --- Vertex AI Vector Search ---
# 1. The Index: stores the vectors.
resource "google_vertex_ai_index" "sanctra" {
  display_name = var.vertex_display_name
  description  = "Stores embeddings for Sanctra personas"
  region       = var.region
  # This metadata configures the index for Approximate Nearest Neighbor (ANN) search.
  # embedding_dimensionality must match your model's output (Gecko is 768).
  metadata = jsonencode({
    contentsDeltaUri = "gs://${module.bucket_uploads.name}/vectors/"
    config = {
      dimensions = 768 # For textembedding-gecko@003
      approximateNeighborsCount = 150
      distanceMeasureType = "DOT_PRODUCT_DISTANCE"
      algorithm_config = {
        treeAhConfig = {
          leafNodeEmbeddingCount = 5000
          leafNodesToSearchPercent = 7
        }
      }
    }
  })
  index_update_method = "STREAM_UPDATE" # Allows for real-time updates
}

# 2. The Index Endpoint: provides a public-facing URL to query the index.
resource "google_vertex_ai_index_endpoint" "sanctra" {
  display_name = "${var.vertex_display_name}-endpoint"
  description  = "Public endpoint for querying the Sanctra index"
  region       = var.region
  # Enable public access so Cloud Run can call it without complex VPC networking.
  public_endpoint_enabled = true
}

# 3. The Deployment: links the Index to the Endpoint.
resource "google_vertex_ai_deployment" "sanctra" {
  project = var.project_id
  # The endpoint ID is the last part of its resource name.
  index_endpoint = split("/", google_vertex_ai_index_endpoint.sanctra.id)[5]
  # The index ID is the last part of its resource name.
  deployed_index_id = "idx_${replace(var.vertex_display_name, "-", "_")}"
  index = split("/", google_vertex_ai_index.sanctra.id)[5]
  display_name = "sanctra_deployment_v1"
  # This tells the deployment to auto-scale, starting with 2 replicas.
  automatic_resources {
    min_replica_count = 2
    max_replica_count = 10
  }
}