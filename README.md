# sanctra-infra

Terraform for Sanctra infrastructure: buckets, Artifact Registry, Cloud Run, GPU MIGs, Vertex AI Vector Search, and secrets. Cloud Build configs included.

## Layout
- envs/prod: root stack wiring modules
- modules/*: reusable modules
- cloudbuild/*.yaml: Cloud Build pipelines for services

## Usage
cd envs/prod
terraform init
terraform plan -var='project_id=YOUR_PROJECT' -var='region=us-central1' -var='github_owner=YOUR_GH_ORG' -var='repo_orchestrator=sanctra-orchestrator' -var='repo_rag=sanctra-rag-service'
terraform apply

Outputs include Cloud Run URLs and MIG templates.

## Notes
- Secrets are created without versions. Add secret versions out-of-band or via CI.
- GPU MIG startup is a stub. Customize image, driver install, and docker run per your stack.
