variable "project_id" { type = string }
variable "region"     { type = string  default = "us-central1" }
variable "location"   { type = string  default = "US" } # for buckets and Artifact Registry
variable "github_owner" { type = string }                 # e.g., sanctra
variable "repo_orchestrator" { type = string default = "sanctra-orchestrator" }
variable "repo_rag"          { type = string default = "sanctra-rag-service" }
variable "branch"            { type = string default = "main" }

# Networking (customize as needed)
variable "network"   { type = string default = "default" }
variable "subnetwork"{ type = string default = "default" }

# Service accounts (supply emails or create separately)
variable "run_sa_email" { type = string default = null }
variable "gpu_sa_email" { type = string default = null }

# Images for services
variable "orchestrator_image" { type = string default = "us-central1-docker.pkg.dev/${var.project_id}/sanctra-docker/sanctra-orchestrator:latest" }
variable "rag_image"          { type = string default = "us-central1-docker.pkg.dev/${var.project_id}/sanctra-docker/sanctra-rag-service:latest" }
variable "asr_image"          { type = string default = "us-central1-docker.pkg.dev/${var.project_id}/sanctra-docker/sanctra-asr-gpu:latest" }
variable "avatar_image"       { type = string default = "us-central1-docker.pkg.dev/${var.project_id}/sanctra-docker/sanctra-avatar-gpu:latest" }

# Vertex AI
variable "vertex_display_name" { type = string default = "sanctra-index" }
variable "vertex_embedding_model" { type = string default = "textembedding-gecko@003" }
